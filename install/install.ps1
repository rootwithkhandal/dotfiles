#Requires -Version 5.1
<#
.SYNOPSIS
    Unified Windows 11 workstation bootstrap & dotfiles installer.
    Merges environment setup, package installations, dotfile deployment,
    and security hardening into an idempotent, phase-aware script.

.DESCRIPTION
    This script can be run locally from a dotfiles clone or streamed directly:

        irm https://raw.githubusercontent.com/rootwithkhandal/dotfiles/main/install.ps1 | iex

    Execution can be filtered by phase or fine-grained flags:
      -Phase Harden : System hardening, Defender, firewall, audit policies (requires Admin)
      -Phase Tools  : Winget, Chocolatey, WSL2, and system developer tools (requires Admin)
      -Phase User   : Scoop, Go/Rust/Python CLI tools, git config, dotfiles (run as standard user)
      -Phase All    : Full workstation setup (elevated; Scoop is deferred if run as Admin)

.PARAMETER Phase
    Target phase: 'All' (default), 'Harden', 'Tools', or 'User'.

.PARAMETER RepositoryPath
    Path to an existing dotfiles repository checkout. Defaults to auto-resolving from script root or parent directories.

.PARAMETER RepositoryUrl
    Git URL used to clone the dotfiles repository if running via web stream.

.PARAMETER GitName
    Git user.name. If omitted, falls back to .env / keys.env, environment variables, or repository defaults.

.PARAMETER GitEmail
    Git user.email. If omitted, falls back to .env / keys.env, environment variables, or repository defaults.

.PARAMETER DotfilesDir
    Directory containing dotfiles configs. Defaults to the resolved repository root.

.PARAMETER BugBountyRoot
    Target root directory for security / bug-bounty workspace (default: C:\bugbounty).

.PARAMETER RegistryMode
    Optional registry preset to import from windows\registry\<mode>\*.reg.

.PARAMETER SkipPackages
    Skip application package installations (winget, choco, scoop).

.PARAMETER SkipModules
    Skip PowerShell module installations.

.PARAMETER SkipConfigs
    Skip dotfile configuration deployments (wezterm, neovim, vscode, profile).

.PARAMETER SkipVBS
    Skip Virtualization-Based Security / HVCI / Credential Guard (recommended on nested VM hosts).

.PARAMETER Security
    Explicit switch to enforce the Windows security hardening baseline (equivalent to -Phase Harden).

.PARAMETER Stow
    Run GNU Stow across the dotfiles repository structure.

.PARAMETER Upgrade
    Run Windows Update and winget upgrade --all.

.PARAMETER Verify
    Display a system posture report after hardening.

.PARAMETER VSCodeGroups
    Subset of VS Code extension groups to install (e.g. Core, Python, Security). Defaults to all groups.

.PARAMETER WhatIf
    Show actions that would be executed without modifying the system.

.EXAMPLE
    irm https://raw.githubusercontent.com/rootwithkhandal/dotfiles/main/install.ps1 | iex
    .\install.ps1 -Phase All
    .\install.ps1 -Phase Harden -Verify
    .\install.ps1 -Phase Tools
    .\install.ps1 -Phase User -GitName "Priyansh Khandal" -GitEmail "i.priyanshkhandal@gmail.com"
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [ValidateSet('All', 'Harden', 'Tools', 'User')][string]$Phase = 'All',
    [string]$RepositoryPath,
    [string]$RepositoryUrl = 'https://github.com/rootwithkhandal/dotfiles.git',
    [string]$GitName,
    [string]$GitEmail,
    [string]$DotfilesDir,
    [string]$BugBountyRoot = 'C:\bugbounty',
    [string]$RegistryMode,
    [switch]$SkipPackages,
    [switch]$SkipModules,
    [switch]$SkipConfigs,
    [switch]$SkipVBS,
    [switch]$Security,
    [switch]$Stow,
    [switch]$Upgrade,
    [switch]$Verify,
    [string[]]$VSCodeGroups
)

# ----------------------------------------------------------------------------
# Initialization & Common Helpers
# ----------------------------------------------------------------------------
$ErrorActionPreference = 'Stop'
$script:Log = [System.Collections.Generic.List[string]]::new()
$script:Fails = 0
$script:TemporaryRepository = $null

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

$isAdmin = Test-Administrator

# If -Security switch was provided, force Harden phase
if ($Security -and $Phase -eq 'All') {
    $Phase = 'Harden'
}

function Test-Phase([string]$Name) {
    if ($Security -and $Name -eq 'Harden') { return $true }
    return ($Phase -eq 'All' -or $Phase -eq $Name)
}

function Write-Step([string]$Msg) {
    Write-Host "`n==> $Msg" -ForegroundColor Cyan
}

function Add-Log([bool]$Ok, [string]$Label, [string]$Detail = '') {
    if ($Ok) {
        $script:Log.Add("[OK]   $Label")
        Write-Host "[OK]   $Label" -ForegroundColor Green
    } else {
        $script:Log.Add("[FAIL] $Label - $Detail")
        $script:Fails++
        Write-Host "[FAIL] $Label - $Detail" -ForegroundColor Red
    }
}

function Step([string]$Label, [scriptblock]$Do) {
    if ($WhatIfPreference) {
        Write-Host "[WHATIF] $Label" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] $Label")
        return
    }
    try {
        $ErrorActionPreference = 'Stop'
        & $Do
        Add-Log $true $Label
    } catch {
        Add-Log $false $Label $_.Exception.Message
    }
}

function Invoke-Native {
    param(
        [Parameter(Mandatory)][string]$Exe,
        [string[]]$ArgList = @(),
        [int[]]$OkCodes = @(0)
    )
    if ($WhatIfPreference) {
        Write-Host "[WHATIF] $Exe $($ArgList -join ' ')" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] $Exe $($ArgList -join ' ')")
        return
    }
    & $Exe @ArgList
    if ($OkCodes -notcontains $LASTEXITCODE) {
        throw "$Exe $($ArgList -join ' ') -> exit code $LASTEXITCODE"
    }
}

function Set-RegValue {
    param([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord')
    if ($WhatIfPreference) {
        Write-Host "[WHATIF] Set Registry $Path :: $Name = $Value ($Type)" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] Registry: $Name = $Value")
        return
    }
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
    New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force | Out-Null
}

function Update-SessionPath {
    $env:Path = ([Environment]::GetEnvironmentVariable('Path', 'Machine'),
                 [Environment]::GetEnvironmentVariable('Path', 'User')) -join ';'
}

function Add-UserPath([string]$Dir) {
    $cur = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (($cur -split ';') -notcontains $Dir) {
        [Environment]::SetEnvironmentVariable('Path', ($cur.TrimEnd(';') + ";$Dir"), 'User')
    }
    if (($env:Path -split ';') -notcontains $Dir) { $env:Path += ";$Dir" }
}

function Resolve-RepositoryRoot {
    if ($RepositoryPath) {
        $resolved = (Resolve-Path -LiteralPath $RepositoryPath -ErrorAction Stop).Path
        if (-not (Test-Path -LiteralPath (Join-Path $resolved "README.md"))) {
            throw "RepositoryPath does not appear to be a dotfiles checkout: $resolved"
        }
        return $resolved
    }

    if ($DotfilesDir -and (Test-Path -LiteralPath (Join-Path $DotfilesDir "README.md"))) {
        return (Resolve-Path -LiteralPath $DotfilesDir).Path
    }

    if ($PSScriptRoot) {
        $parent = Split-Path -Parent $PSScriptRoot
        if (Test-Path -LiteralPath (Join-Path $PSScriptRoot "README.md")) {
            return $PSScriptRoot
        } elseif (Test-Path -LiteralPath (Join-Path $parent "README.md")) {
            return $parent
        }
    }

    if (Test-Path -LiteralPath ".\README.md") {
        return (Resolve-Path -LiteralPath ".").Path
    }

    # Streamed execution (irm ... | iex) on a fresh machine
    $script:TemporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-install-$([guid]::NewGuid())"
    New-Item -ItemType Directory -Force -Path $script:TemporaryRepository | Out-Null

    if (Get-Command git -ErrorAction SilentlyContinue) {
        Write-Step "Cloning dotfiles repository from $RepositoryUrl..."
        Invoke-Native git @('clone', '--depth', '1', '--', $RepositoryUrl, $script:TemporaryRepository)
        return $script:TemporaryRepository
    }

    # Fallback if Git is not yet installed: download GitHub archive ZIP
    Write-Step "Git not detected. Downloading dotfiles archive from GitHub..."
    $zipUrl = "https://github.com/rootwithkhandal/dotfiles/archive/refs/heads/main.zip"
    $tempZip = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-archive-$([guid]::NewGuid()).zip"
    Invoke-WebRequest -UseBasicParsing -Uri $zipUrl -OutFile $tempZip
    Expand-Archive -Path $tempZip -DestinationPath $script:TemporaryRepository -Force
    Remove-Item -Path $tempZip -Force -ErrorAction SilentlyContinue

    $extractedDir = Join-Path $script:TemporaryRepository "dotfiles-main"
    if (Test-Path $extractedDir) {
        return $extractedDir
    }
    return $script:TemporaryRepository
}

# ----------------------------------------------------------------------------
# Package Manager Helpers
# ----------------------------------------------------------------------------
function Install-Winget([string]$Id, [string[]]$Extra = @()) {
    if ($WhatIfPreference) {
        Write-Host "[WHATIF] winget install $Id" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] [winget] $Id")
        return
    }
    & winget install --id $Id -e --silent --accept-package-agreements --accept-source-agreements --no-upgrade @Extra | Out-Null
    # winget codes: 0 = ok, -1978335189 = no applicable update, -1978335135 = already installed
    $ok = @(0, -1978335189, -1978335135) -contains $LASTEXITCODE
    Add-Log $ok "[winget] $Id" "exit $LASTEXITCODE"
}

function Install-Choco([string]$Id) {
    if ($WhatIfPreference) {
        Write-Host "[WHATIF] choco install $Id" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] [choco] $Id")
        return
    }
    & choco install $Id -y --no-progress | Out-Null
    # choco codes: 0 = ok, 1641 / 3010 = reboot initiated/required
    $ok = @(0, 1641, 3010) -contains $LASTEXITCODE
    Add-Log $ok "[choco]  $Id" "exit $LASTEXITCODE"
}

# ----------------------------------------------------------------------------
# Posture Verification Report
# ----------------------------------------------------------------------------
function Show-Posture {
    Write-Step 'System Posture Report'
    if (Get-Command Get-MpComputerStatus -ErrorAction SilentlyContinue) {
        Get-MpComputerStatus | Select-Object AMServiceEnabled, AntivirusEnabled, RealTimeProtectionEnabled, NISEnabled | Format-List
    }
    if (Get-Command Get-MpPreference -ErrorAction SilentlyContinue) {
        $p = Get-MpPreference
        Write-Host "Attack Surface Reduction Rules:"
        for ($i = 0; $i -lt $p.AttackSurfaceReductionRules_Ids.Count; $i++) {
            '{0}  action={1}' -f $p.AttackSurfaceReductionRules_Ids[$i], $p.AttackSurfaceReductionRules_Actions[$i]
        }
    }
    if (Get-Command Get-CimInstance -ErrorAction SilentlyContinue) {
        Get-CimInstance -ClassName Win32_DeviceGuard -Namespace root\Microsoft\Windows\DeviceGuard -ErrorAction SilentlyContinue |
            Select-Object SecurityServicesRunning, VirtualizationBasedSecurityStatus | Format-List
    }
    Write-Host 'Listening TCP ports:'
    Get-NetTCPConnection -State Listen -ErrorAction SilentlyContinue |
        Select-Object LocalAddress, LocalPort, OwningProcess | Sort-Object LocalPort | Format-Table -AutoSize
    Write-Host 'Inbound ALLOW rules matching Any port (review):'
    Get-NetFirewallRule -Direction Inbound -Action Allow -Enabled True -ErrorAction SilentlyContinue |
        Get-NetFirewallPortFilter | Where-Object { $_.LocalPort -eq 'Any' } |
        Select-Object InstanceID, Protocol | Format-Table -AutoSize
}

# ----------------------------------------------------------------------------
# VS Code Extensions Catalog & Loader
# ----------------------------------------------------------------------------
$VSCodeExtensions = [ordered]@{
    CodeQualityFormatting = @(
        'aaron-bond.better-comments', 'charliermarsh.ruff', 'davidanson.vscode-markdownlint',
        'dbaeumer.vscode-eslint', 'esbenp.prettier-vscode', 'ms-python.black-formatter',
        'ms-python.isort', 'oderwat.indent-rainbow', 'streetsidesoftware.code-spell-checker',
        'usernamehw.errorlens'
    )
    PythonDevelopment     = @(
        'ms-python.python', 'ms-python.vscode-pylance', 'ms-python.debugpy',
        'donjayamanne.python-environment-manager', 'donjayamanne.python-extension-pack',
        'kevinrose.vsc-python-indent', 'njpwerner.autodocstring', 'batisteo.vscode-django',
        'ms-vscode.vscode-python-envs', 'tht13.python', 'wolfieshorizon.python-auto-venv'
    )
    AICodeAssistance      = @(
        'continue.continue', 'github.copilot', 'github.copilot-chat',
        'tabnine.tabnine-vscode', 'visualstudioexptteam.intellicode-api-usage-examples',
        'visualstudioexptteam.vscodeintellicode', 'anthropic.claude-code', 'blackboxapp.blackboxagent'
    )
    WebDevelopment        = @(
        'ecmel.vscode-html-css', 'formulahendry.auto-rename-tag', 'formulahendry.auto-close-tag',
        'ritwickdey.liveserver', 'dsznajder.es7-react-js-snippets', 'xabikos.javascriptsnippets',
        'christian-kohler.npm-intellisense', 'christian-kohler.path-intellisense',
        'pranaygp.vscode-css-peek', 'techer.open-in-browser', 'quicktype.quicktype'
    )
    PHPDevelopment        = @(
        'bmewburn.vscode-intelephense-client', 'brapifra.phpserver', 'xdebug.php-debug',
        'xdebug.php-pack', 'zobo.php-intellisense'
    )
    GoDevelopment         = @('golang.go')
    RustDevelopment       = @('rust-lang.rust-analyzer')
    CCDevelopment         = @(
        'ms-vscode.cpptools', 'ms-vscode.cpptools-extension-pack',
        'ms-vscode.cpptools-themes', 'ms-vscode.cmake-tools', 'twxs.cmake'
    )
    JavaDevelopment       = @('redhat.java', 'vscjava.vscode-java-debug')
    DartFlutter           = @('dart-code.dart-code', 'dart-code.flutter')
    RubyDevelopment       = @('rebornix.ruby')
    SolidityBlockchain    = @(
        'juanblanco.solidity', 'nomicfoundation.hardhat-solidity',
        'tintinweb.solidity-visual-auditor', 'tintinweb.vscode-solidity-flattener',
        'tintinweb.vscode-solidity-metrics'
    )
    DevOpsCloud           = @(
        'ms-azuretools.vscode-docker', 'ms-azuretools.vscode-containers',
        'ms-azuretools.vscode-azurefunctions', 'ms-kubernetes-tools.vscode-kubernetes-tools',
        'ms-vscode.azure-repos', 'hashicorp.terraform', 'redhat.ansible',
        'redhat.vscode-yaml', 'ivanarjona.cloudflaretunnel', 'bencoleman.armview'
    )
    RemoteDevelopment     = @(
        'ms-vscode-remote.remote-ssh', 'ms-vscode-remote.remote-ssh-edit',
        'ms-vscode-remote.remote-wsl', 'ms-vscode-remote.remote-containers',
        'ms-vscode-remote.vscode-remote-extensionpack', 'ms-vscode.remote-explorer',
        'ms-vscode.remote-server', 'ms-vsliveshare.vsliveshare'
    )
    DatabaseData          = @(
        'mtxr.sqltools', 'mtxr.sqltools-driver-mysql', 'mtxr.sqltools-driver-sqlite',
        'qwtel.sqlite-viewer', 'yurialvesguernsey.localastrodb', 'mechatroner.rainbow-csv',
        'chandan-sharma.csv-reader', 'ms-toolsai.jupyter', 'ms-toolsai.jupyter-keymap',
        'ms-toolsai.jupyter-renderers', 'ms-toolsai.vscode-jupyter-cell-tags',
        'ms-toolsai.vscode-jupyter-slideshow'
    )
    GitVersionControl     = @('eamodio.gitlens')
    APIDevelopment        = @('postman.postman-for-vscode')
    SecurityPentesting    = @(
        'silofy.hackthebox', 'jamiewoodio.cisco', 'tintinweb.vscode-security-auditor',
        'infosec.vscode-nmap', 'muteki.vscode-pcap', 'sandcastle.vscode-open-in-burp',
        'elastic.elastic-vscode', 'githyanki.debugtron'
    )
    JSONTools             = @('aykutsarac.jsoncrack-vscode', 'kakumei.jsontools')
    Themes                = @(
        'cocopon.iceberg-theme', 'davidbwaters.macos-modern-theme', 'pkief.material-icon-theme',
        'whizkydee.material-palenight-theme', 'zhuangtongfa.material-theme', 'enkia.tokyo-night',
        'catppuccin.catppuccin-vsc', 'akamud.vscode-theme-onedark', 'vscode-icons-team.vscode-icons'
    )
    Utilities             = @(
        'formulahendry.code-runner', 'mutantdino.resourcemonitor', 's-nlf-fh.glassit',
        'glassit.alpha', 'johnpapa.vscode-peacock', 'shalldie.background',
        'gruntfuggly.todo-tree', 'spmeesseman.vscode-taskexplorer', 'wmaurer.change-case',
        'naumovs.color-highlight', 'spywhere.guides', 'ionutvmi.path-autocomplete',
        'mindaro-dev.file-downloader', 'be5invis.vscode-custom-css'
    )
    TemplatesAndShell     = @(
        'samuelcolvin.jinjahtml', 'wholroyd.jinja', 'ms-vscode.powershell',
        'foxundermoon.shell-format', 'timonwong.shellcheck', 'mads-hartmann.bash-ide-vscode',
        'shakram02.bash-beautify', 'almenon.arepl'
    )
    RedHatTools           = @(
        'redhat.vscode-extension-dashbuilder-editor', 'redhat.vscode-extension-dmn-editor',
        'redhat.vscode-kaoto', 'redhat.vscode-openshift-connector',
        'redhat.vscode-redhat-account', 'redhat.vscode-rsp-ui', 'redhat.vscode-xml'
    )
}

function Load-VSCodeExtensionsFromYaml([string]$Root) {
    if (-not $Root) { return }
    $candidates = @(
        (Join-Path $Root "scripts\config\vscode_extensions.yaml"),
        (Join-Path $Root "config\vscode_extensions.yaml"),
        ".\vscode_extensions.yaml"
    )
    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            $currentCat = "General"
            Get-Content $candidate | ForEach-Object {
                $line = $_.Trim()
                if ($line -match '^#\s*(.+)$') {
                    $cat = ($matches[1].Trim() -replace '[^a-zA-Z0-9]', '')
                    if ($cat) {
                        $currentCat = $cat
                        if (-not $script:VSCodeExtensions.Contains($currentCat)) {
                            $script:VSCodeExtensions[$currentCat] = [System.Collections.Generic.List[string]]::new()
                        }
                    }
                } elseif ($line -match '^-\s*([a-zA-Z0-9_.-]+)$') {
                    $id = $matches[1].Trim()
                    if (-not $script:VSCodeExtensions.Contains($currentCat)) {
                        $script:VSCodeExtensions[$currentCat] = [System.Collections.Generic.List[string]]::new()
                    }
                    if ($script:VSCodeExtensions[$currentCat] -notcontains $id) {
                        [void]$script:VSCodeExtensions[$currentCat].Add($id)
                    }
                }
            }
            break
        }
    }
}

function Install-VSCodeExtensions {
    param([string[]]$Group, [string]$Root)
    if ($Root) { Load-VSCodeExtensionsFromYaml -Root $Root }

    if (-not $Group) { $Group = @($script:VSCodeExtensions.Keys) }
    $keys = @($script:VSCodeExtensions.Keys)
    $resolvedGroups = [System.Collections.Generic.List[string]]::new()

    foreach ($g in $Group) {
        $match = $keys | Where-Object { $_ -eq $g -or $_ -like "*$g*" }
        if ($match) {
            foreach ($m in $match) {
                if (-not $resolvedGroups.Contains($m)) { $resolvedGroups.Add($m) }
            }
        } else {
            throw "Unknown VS Code group '$g'. Valid groups: $($keys -join ', ')"
        }
    }

    if ($WhatIfPreference) {
        Write-Host "[WHATIF] Install VS Code extension groups: $($resolvedGroups -join ', ')" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] [vscode] groups: $($resolvedGroups -join ', ')")
        return
    }

    $prevEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        if (-not (Get-Command code -ErrorAction SilentlyContinue)) {
            throw "'code' command not found on PATH."
        }

        $ids = $resolvedGroups | ForEach-Object { $script:VSCodeExtensions[$_] } |
               ForEach-Object { $_.ToLowerInvariant() } | Select-Object -Unique
        $have = @(& code --list-extensions 2>$null | ForEach-Object { $_.Trim().ToLowerInvariant() })

        $skipped = 0
        foreach ($id in $ids) {
            if ($have -contains $id) { $skipped++; continue }
            $out = & code --install-extension $id 2>&1 | Out-String
            $ok = ($LASTEXITCODE -eq 0) -and ($out -notmatch 'not found|failed|error')
            Add-Log $ok "[vscode] $id" (($out.Trim() -split "`r?`n")[0])
        }
        $script:Log.Add("[OK]   [vscode] $skipped extension(s) already installed (groups: $($resolvedGroups -join ', '))")
    } finally {
        $ErrorActionPreference = $prevEAP
    }
}

# ----------------------------------------------------------------------------
# Dotfiles Deployment Helpers
# ----------------------------------------------------------------------------
function Deploy-Config([string]$Src, [string]$Dest) {
    if (-not (Test-Path $Src)) {
        $script:Log.Add("[SKIP] config not found: $Src")
        return
    }
    if ($WhatIfPreference) {
        Write-Host "[WHATIF] Deploy $Src -> $Dest" -ForegroundColor Yellow
        $script:Log.Add("[WHATIF] config deployed: $Dest")
        return
    }
    if ((Test-Path $Dest) -and -not (Test-Path "$Dest.bak")) {
        Move-Item $Dest "$Dest.bak" -Force
    } elseif (Test-Path $Dest) {
        Remove-Item $Dest -Recurse -Force
    }
    New-Item -ItemType Directory -Force -Path (Split-Path $Dest) | Out-Null
    Copy-Item $Src $Dest -Recurse -Force
    Add-Log $true "Deploy config: $Dest"
}

function Import-RegistryFiles([string]$Root, [string]$Mode) {
    $dir = Join-Path $Root "windows\registry\$Mode"
    if (-not (Test-Path -LiteralPath $dir)) {
        $dir = Join-Path $Root "dotfiles\windows\registry\$Mode"
    }
    if (-not (Test-Path -LiteralPath $dir)) {
        throw "Registry folder not found: $dir"
    }
    Get-ChildItem -LiteralPath $dir -Filter '*.reg' | Sort-Object Name | ForEach-Object {
        Write-Host "Importing $($_.Name)"
        Invoke-Native reg @('import', $_.FullName)
    }
}

function Invoke-StowAll([string]$Root, [string]$TargetDir = $HOME) {
    if (-not (Get-Command stow -ErrorAction SilentlyContinue)) {
        throw 'GNU Stow was not found on PATH.'
    }
    $globs = 'windows\assets\*', 'windows\browser\*', 'windows\editor\*', 'windows\obsidian', 'windows\security\*',
             'windows\shell', 'windows\ssh', 'windows\terminal\*', 'windows\wallpaper', 'windows\wsl'
    foreach ($g in $globs) {
        Get-ChildItem -Path (Join-Path $Root $g) -Directory -ErrorAction SilentlyContinue | ForEach-Object {
            if ($_.Name -eq 'windows-terminal') {
                Write-Host 'Skipping windows-terminal (manage settings.json manually).'
                return
            }
            Invoke-Native stow @('-d', $_.Parent.FullName, '-t', $TargetDir, $_.Name)
        }
    }
}

# ----------------------------------------------------------------------------
# MAIN EXECUTION FLOW
# ----------------------------------------------------------------------------
try {
    $repoRoot = Resolve-RepositoryRoot
    Write-Host "Using dotfiles repository: $repoRoot" -ForegroundColor Gray

    # Locate dotfiles configuration tree
    $dotfilesRoot = $repoRoot
    if (Test-Path (Join-Path $repoRoot "dotfiles\nvim")) {
        $dotfilesRoot = Join-Path $repoRoot "dotfiles"
    }

    # ========================================================================
    # PHASE 1 - HARDEN (Security Baseline)
    # ========================================================================
    if (Test-Phase 'Harden') {
        if (-not $isAdmin -and -not $WhatIfPreference) {
            if ($Phase -eq 'All') {
                $script:Log.Add("[SKIP] Harden - requires Administrator session (run as Admin to apply security baseline)")
                Write-Host "[SKIP] Harden - requires Administrator session (run as Admin to apply security baseline)" -ForegroundColor Yellow
            } else {
                throw "Security hardening (-Phase Harden / -Security) requires an elevated Administrator session."
            }
        } else {
            Write-Step 'Services, legacy protocols, and network resolution hardening'

            Step 'Disable unused services' {
                foreach ($n in 'RemoteRegistry', 'Fax', 'WMPNetworkSvc', 'MapsBroker') {
                    if (Get-Service $n -ErrorAction SilentlyContinue) {
                        Stop-Service $n -Force -ErrorAction SilentlyContinue
                        Set-Service  $n -StartupType Disabled
                    }
                }
            }

            Step 'Disable SMBv1' {
                $f = Get-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -ErrorAction SilentlyContinue
                if ($f -and $f.State -ne 'Disabled') {
                    Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart | Out-Null
                }
            }

            Step 'Disable LLMNR, NetBIOS-over-TCP, AutoRun, and RDP' {
                Set-RegValue 'HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient' 'EnableMulticast' 0
                Get-CimInstance Win32_NetworkAdapterConfiguration -Filter 'IPEnabled=True' -ErrorAction SilentlyContinue | ForEach-Object {
                    Invoke-CimMethod -InputObject $_ -MethodName SetTcpipNetbios -Arguments @{ TcpipNetbiosOptions = 2 } | Out-Null
                }
                foreach ($hive in 'HKLM', 'HKCU') {
                    Set-RegValue "${hive}:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" 'NoDriveTypeAutoRun' 255
                }
                Set-RegValue 'HKLM:\System\CurrentControlSet\Control\Terminal Server' 'fDenyTSConnections' 1
            }

            Write-Step 'Firewall baseline'

            Step 'Configure Windows Firewall profiles and deny rules' {
                Set-NetFirewallProfile -Profile Domain, Public, Private -Enabled True `
                    -DefaultInboundAction Block -DefaultOutboundAction Allow `
                    -LogBlocked True -LogAllowed False -LogMaxSizeKilobytes 32767 `
                    -LogFileName '%systemroot%\system32\LogFiles\Firewall\pfirewall.log'

                $blocks = @(
                    @{ Name = 'Block SMB Inbound';   Port = @('445') },
                    @{ Name = 'Block RDP Public';    Port = @('3389') },
                    @{ Name = 'Block WinRM Public';  Port = @('5985', '5986') }
                )
                foreach ($b in $blocks) {
                    if (-not (Get-NetFirewallRule -DisplayName $b.Name -ErrorAction SilentlyContinue)) {
                        New-NetFirewallRule -DisplayName $b.Name -Direction Inbound -Protocol TCP `
                            -LocalPort $b.Port -Action Block -Profile Public | Out-Null
                    }
                }
                Get-NetFirewallRule -DisplayGroup 'File and Printer Sharing', 'Remote Desktop' -ErrorAction SilentlyContinue |
                    Set-NetFirewallRule -Enabled False
            }

            Write-Step 'Auditing and logging'

            Step 'Set advanced audit policy' {
                $cats = 'Account Logon', 'Account Management', 'Logon/Logoff', 'Object Access',
                        'Policy Change', 'Privilege Use', 'Detailed Tracking', 'System'
                foreach ($c in $cats) {
                    Invoke-Native auditpol @('/set', "/category:$c", '/success:enable', '/failure:enable') | Out-Null
                }
            }

            Step 'Set event log sizes and enable command line auditing in 4688' {
                $logs = [ordered]@{
                    'Security'                                = 1GB
                    'System'                                  = 256MB
                    'Application'                             = 256MB
                    'Microsoft-Windows-PowerShell/Operational' = 256MB
                    'Microsoft-Windows-DNS-Client/Operational' = 256MB
                }
                foreach ($k in $logs.Keys) {
                    Invoke-Native wevtutil @('sl', $k, "/ms:$($logs[$k])", '/e:true')
                }
                Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System\Audit' 'ProcessCreationIncludeCmdLine_Enabled' 1
            }

            Step 'Enable PowerShell script block, module logging, and transcription' {
                $ps = 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\PowerShell'
                Set-RegValue "$ps\ScriptBlockLogging" 'EnableScriptBlockLogging' 1
                Set-RegValue "$ps\ModuleLogging"      'EnableModuleLogging'      1
                Set-RegValue "$ps\ModuleLogging\ModuleNames" '*' '*' 'String'
                Set-RegValue "$ps\Transcription" 'EnableTranscripting'    1
                Set-RegValue "$ps\Transcription" 'EnableInvocationHeader' 1
                Set-RegValue "$ps\Transcription" 'OutputDirectory' 'C:\PSTranscripts' 'String'
                New-Item -ItemType Directory -Force -Path 'C:\PSTranscripts' | Out-Null
            }

            Write-Step 'Microsoft Defender & ASR'

            Step 'Configure Defender baseline' {
                Set-MpPreference -DisableRealtimeMonitoring $false -DisableBehaviorMonitoring $false `
                    -MAPSReporting Advanced -SubmitSamplesConsent SendSafeSamples `
                    -EnableNetworkProtection Enabled -PUAProtection Enabled
            }

            Step 'Apply Attack Surface Reduction (ASR) rules' {
                $asr = @(
                    @('3B576869-A4EC-4529-8536-B80A7769E899', 'Enabled'),
                    @('D4F940AB-401B-4EFC-AADC-AD5F3C50688A', 'Enabled'),
                    @('75668C1F-73B5-4CF0-BB93-3ECF5CB7CC84', 'Enabled'),
                    @('92E97FA1-2EDF-4476-BDD6-9DD0B4DDDC7B', 'Enabled'),
                    @('26190899-1602-49E8-8B27-EB1D0A1CE869', 'Enabled'),
                    @('BE9BA2D9-53EA-4CDC-84E5-9B1EEEE46550', 'Enabled'),
                    @('5BEB7EFE-FD9A-4556-801D-275E5FFC04CC', 'Enabled'),
                    @('D3E037E1-3EB8-44C8-A917-57927947596D', 'Enabled'),
                    @('9E6C4E1F-7D60-472F-BA1A-A39EF669E4B2', 'Enabled'),
                    @('C1DB55AB-C21A-4637-BB3F-A12568109D35', 'Enabled'),
                    @('01443614-CD74-433A-B99E-2ECDC07BFC25', 'AuditMode')
                )
                Add-MpPreference -AttackSurfaceReductionRules_Ids ($asr | ForEach-Object { $_[0] }) `
                                 -AttackSurfaceReductionRules_Actions ($asr | ForEach-Object { $_[1] })
                Update-MpSignature
            }

            Write-Step 'Credential & OS hardening'

            Step 'Disable PowerShell v2 & set ExecutionPolicy RemoteSigned' {
                $f = Get-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -ErrorAction SilentlyContinue
                if ($f -and $f.State -eq 'Enabled') {
                    Disable-WindowsOptionalFeature -Online -FeatureName MicrosoftWindowsPowerShellV2Root -NoRestart | Out-Null
                }
                Set-ExecutionPolicy RemoteSigned -Scope LocalMachine -Force
            }

            Step 'LSA protection, WDigest, NTLM audit, and cached logon restrictions' {
                Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' 'RunAsPPL' 2
                Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\WDigest' 'UseLogonCredential' 0
                Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' 'RestrictSendingNTLMTraffic' 1
                Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa\MSV1_0' 'AuditReceivingNTLMTraffic'  2
                Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon' 'CachedLogonsCount' '0' 'String'
            }

            if (-not $SkipVBS) {
                Step 'Virtualization-Based Security, HVCI, and Credential Guard' {
                    $dg = 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard'
                    Set-RegValue $dg 'EnableVirtualizationBasedSecurity' 1
                    Set-RegValue $dg 'RequirePlatformSecurityFeatures'   1
                    Set-RegValue "$dg\Scenarios\HypervisorEnforcedCodeIntegrity" 'Enabled' 1
                    Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\Lsa' 'LsaCfgFlags' 2
                }
            }

            Step 'Developer OS enhancements' {
                Set-RegValue 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'LongPathsEnabled' 1
                Set-RegValue 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock' 'AllowDevelopmentWithoutDevLicense' 1
                Set-RegValue 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
            }

            if ($Verify) { Show-Posture }
        }
    }

    # ========================================================================
    # PHASE 2 - TOOLS (Winget, Chocolatey, WSL2)
    # ========================================================================
    if (Test-Phase 'Tools' -and -not $SkipPackages) {
        if (-not $isAdmin -and -not $WhatIfPreference) {
            if ($Phase -eq 'All') {
                $script:Log.Add("[SKIP] Tools - requires Administrator session for winget/choco/WSL installs")
                Write-Host "[SKIP] Tools - requires Administrator session for winget/choco/WSL installs" -ForegroundColor Yellow
            } else {
                throw "Phase Tools requires an elevated Administrator session."
            }
        } else {
            Write-Step 'Package managers bootstrap'

            Step 'Chocolatey' {
                if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
                    Set-ExecutionPolicy Bypass -Scope Process -Force
                    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor 3072
                    Invoke-Expression ((New-Object Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
                    Update-SessionPath
                }
            }

            Write-Step 'Winget packages installation'
            $wingetPackages = @(
                # Shell / Editors
                'Microsoft.PowerShell', 'Microsoft.WindowsTerminal', 'Microsoft.VisualStudioCode', 'Neovim.Neovim',
                'JetBrains.Toolbox', 'JanDeDobbeleer.OhMyPosh', 'ajeetdsouza.zoxide', 'Atuinsh.Atuin',
                # Runtimes & Languages
                'Git.Git', 'GitHub.cli', 'Python.Python.3.12', 'Python.Launcher', 'astral-sh.uv', 'jdx.mise',
                'GoLang.Go', 'Rustlang.Rustup', 'OpenJS.NodeJS.LTS', 'Microsoft.DotNet.SDK.8',
                # Containers / API / Network
                'Docker.DockerDesktop', 'Postman.Postman', 'Bruno.Bruno', 'HTTPie.HTTPie', 'ngrok.ngrok',
                # Security / Recon
                'Nmap.Nmap', 'WiresharkFoundation.Wireshark', 'PortSwigger.BurpSuite.Community', 'epi052.feroxbuster',
                # Browsers / Desktop Apps / Utilities
                'Google.Chrome', 'Mozilla.Firefox', 'Zen-Team.Zen-Browser', 'Brave.Brave',
                'Obsidian.Obsidian', 'Notion.Notion', 'Figma.Figma', 'Microsoft.PowerToys',
                'voidtools.Everything', 'TablePlus.TablePlus'
            )

            foreach ($id in $wingetPackages) {
                Install-Winget $id
            }

            # Optional winget-packages.json import if present in repo
            $wingetJson = Join-Path $repoRoot "winget-packages.json"
            if (Test-Path $wingetJson) {
                Step 'Import additional winget packages from winget-packages.json' {
                    $manifest = Get-Content $wingetJson -Raw | ConvertFrom-Json
                    foreach ($pkg in $manifest.Sources[0].Packages) {
                        if ($wingetPackages -notcontains $pkg.PackageIdentifier) {
                            Install-Winget $pkg.PackageIdentifier
                        }
                    }
                }
            }

            Write-Step 'Chocolatey security packages'
            foreach ($id in 'masscan', 'netcat', 'maltego', 'metasploit', 'openvpn') {
                Install-Choco $id
            }

            Write-Step 'WSL2 (Ubuntu + Kali Linux)'
            Step 'WSL installation and updates' {
                Invoke-Native wsl @('--install', '-d', 'Ubuntu', '--no-launch')
                Invoke-Native wsl @('--install', '-d', 'kali-linux', '--no-launch')
                Invoke-Native wsl @('--update')
            }

            Update-SessionPath
        }
    }

    # ========================================================================
    # PHASE 3 - USER (Non-Admin Tooling & Dotfiles)
    # ========================================================================
    if (Test-Phase 'User') {
        Update-SessionPath

        # Scoop package manager (cannot run as Administrator)
        if (-not $SkipPackages) {
            Write-Step 'Scoop package manager and CLI tools'
            if ($isAdmin) {
                $script:Log.Add("[SKIP] scoop - run from a non-admin PowerShell: .\install.ps1 -Phase User")
                Write-Host "[SKIP] scoop - Scoop cannot install under Admin. Run in a normal PowerShell: .\install.ps1 -Phase User" -ForegroundColor Yellow
            } else {
                Step 'Scoop + CLI tools' {
                    Set-ExecutionPolicy RemoteSigned -Scope CurrentUser -Force
                    if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
                        Invoke-RestMethod https://get.scoop.sh | Invoke-Expression
                        Update-SessionPath
                    }
                    scoop bucket add extras 2>$null
                    scoop install ripgrep fd bat delta fzf jq yq hyperfine tokei make just
                }
            }
        }

        # PowerShell modules
        if (-not $SkipModules) {
            Write-Step 'PowerShell modules'
            Step 'Install core PowerShell productivity modules' {
                foreach ($m in 'PSReadLine', 'Terminal-Icons', 'posh-git', 'PSFzf') {
                    Install-Module $m -Scope CurrentUser -Force -SkipPublisherCheck -AllowClobber
                }
            }
        }

        # Git Configuration
        Write-Step 'Git configuration'
        Step 'Configure Git defaults and user identity' {
            # Attempt to resolve Git name and email from arguments, env files, or defaults
            if (-not $GitName -or -not $GitEmail) {
                foreach ($envFile in (Join-Path $repoRoot ".env"), (Join-Path $repoRoot "keys.env"), ".\.env", ".\keys.env") {
                    if (Test-Path $envFile) {
                        Get-Content $envFile | ForEach-Object {
                            if ($_ -match "^\s*GIT_USER_NAME\s*=\s*(.*)$") {
                                if (-not $GitName) { $GitName = $matches[1].Trim(' "''') }
                            }
                            if ($_ -match "^\s*GIT_USER_EMAIL\s*=\s*(.*)$") {
                                if (-not $GitEmail) { $GitEmail = $matches[1].Trim(' "''') }
                            }
                        }
                    }
                }
            }

            if (-not $GitName -and $env:GIT_USER_NAME) { $GitName = $env:GIT_USER_NAME }
            if (-not $GitEmail -and $env:GIT_USER_EMAIL) { $GitEmail = $env:GIT_USER_EMAIL }

            if (-not $GitName) { $GitName = "rootwithkhandal" }
            if (-not $GitEmail) { $GitEmail = "i.priyanshkhandal@gmail.com" }

            git config --global user.name  $GitName
            git config --global user.email $GitEmail

            $gitSettings = [ordered]@{
                'init.defaultBranch'  = 'main'
                'core.autocrlf'       = 'input'
                'pull.rebase'         = 'true'
                'core.editor'         = 'code --wait'
                'credential.helper'   = 'manager'
                'diff.tool'           = 'vscode'
                'difftool.vscode.cmd' = 'code --wait --diff $LOCAL $REMOTE'
                'merge.tool'          = 'vscode'
                'alias.st'            = 'status'
                'alias.co'            = 'checkout'
                'alias.br'            = 'branch'
                'alias.lg'            = 'log --oneline --graph --decorate --all'
                'alias.undo'          = 'reset HEAD~1 --mixed'
                'alias.wip'           = "commit -am 'WIP'"
            }
            foreach ($k in $gitSettings.Keys) {
                git config --global $k $gitSettings[$k]
            }
        }

        # Node.js Extras
        if (-not $SkipPackages) {
            Write-Step 'Node.js package managers'
            Step 'Enable Corepack or install pnpm and yarn globally' {
                if (Get-Command corepack -ErrorAction SilentlyContinue) {
                    corepack enable
                } elseif (Get-Command npm -ErrorAction SilentlyContinue) {
                    npm install -g pnpm yarn
                }
            }

            # Python Tooling (uv)
            Write-Step 'Python CLI utilities and virtual environments'
            if (Get-Command uv -ErrorAction SilentlyContinue) {
                Step 'Install Python tools with uv' {
                    foreach ($t in 'poetry', 'black', 'flake8', 'mypy', 'ipython', 'httpie', 'sqlmap', 'dnsrecon', 'shodan', 'censys') {
                        uv tool install $t
                    }
                    New-Item -ItemType Directory -Force -Path $BugBountyRoot | Out-Null
                    uv venv "$BugBountyRoot\.venv"
                    uv pip install --python "$BugBountyRoot\.venv\Scripts\python.exe" requests httpx beautifulsoup4 lxml dnspython
                }
            }

            # Rust Toolchain
            Write-Step 'Rust toolchain and cargo extensions'
            if (Get-Command rustup -ErrorAction SilentlyContinue) {
                Step 'Configure rustup and install cargo utilities' {
                    Add-UserPath "$HOME\.cargo\bin"
                    rustup default stable
                    rustup component add rustfmt clippy rust-analyzer
                    foreach ($c in 'cargo-watch', 'cargo-edit', 'cargo-audit') {
                        cargo install $c
                    }
                }
            }

            # Go Tooling
            Write-Step 'Go development and reconnaissance tooling'
            if (Get-Command go -ErrorAction SilentlyContinue) {
                Add-UserPath "$HOME\go\bin"
                Add-UserPath "$HOME\.local\bin"
                $goTools = @(
                    'golang.org/x/tools/gopls@latest', 'github.com/go-delve/delve/cmd/dlv@latest',
                    'github.com/air-verse/air@latest', 'golang.org/x/tools/cmd/goimports@latest',
                    'github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest',
                    'github.com/projectdiscovery/httpx/cmd/httpx@latest',
                    'github.com/projectdiscovery/dnsx/cmd/dnsx@latest',
                    'github.com/projectdiscovery/katana/cmd/katana@latest',
                    'github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest',
                    'github.com/projectdiscovery/interactsh/cmd/interactsh-client@latest',
                    'github.com/owasp-amass/amass/v4/...@master',
                    'github.com/tomnomnom/assetfinder@latest', 'github.com/tomnomnom/waybackurls@latest', 'github.com/tomnomnom/gf@latest',
                    'github.com/lc/gau/v2/cmd/gau@latest', 'github.com/hakluke/hakrawler@latest',
                    'github.com/d3mondev/puredns/v2@latest', 'github.com/sensepost/gowitness@latest',
                    'github.com/ffuf/ffuf/v2@latest', 'github.com/OJ/gobuster/v3@latest', 'github.com/hahwul/dalfox/v2@latest',
                    'github.com/PentestPad/subzy@latest', 'github.com/haccer/subjack@latest', 'github.com/gitleaks/gitleaks/v8@latest'
                )
                foreach ($pkg in $goTools) {
                    Step "[go] $pkg" { Invoke-Native go @('install', $pkg) }
                }
            }

            # Bug Bounty Workspace Setup
            Write-Step 'Bug-bounty workspace configuration'
            Step 'Prepare directory hierarchy, payloads, and wordlists' {
                'tools', 'wordlists', 'payloads', 'reports',
                'programs\hackerone', 'programs\bugcrowd', 'programs\intigriti', 'programs\yeswehack' |
                    ForEach-Object { New-Item -ItemType Directory -Force -Path (Join-Path $BugBountyRoot $_) | Out-Null }

                $pat = Join-Path $BugBountyRoot 'payloads\PayloadsAllTheThings'
                if (-not (Test-Path $pat) -and (Get-Command git -ErrorAction SilentlyContinue)) {
                    Invoke-Native git @('clone', '--depth', '1', 'https://github.com/swisskyrepo/PayloadsAllTheThings', $pat)
                }

                $gfSrc = Join-Path $BugBountyRoot 'tools\Gf-Patterns'
                if (-not (Test-Path $gfSrc) -and (Get-Command git -ErrorAction SilentlyContinue)) {
                    Invoke-Native git @('clone', '--depth', '1', 'https://github.com/1ndianl33t/Gf-Patterns', $gfSrc)
                }
                New-Item -ItemType Directory -Force -Path "$HOME\.gf" | Out-Null
                if (Test-Path "$gfSrc\*.json") {
                    Copy-Item "$gfSrc\*.json" "$HOME\.gf" -Force
                }

                Invoke-WebRequest -UseBasicParsing -Uri 'https://raw.githubusercontent.com/trickest/resolvers/main/resolvers.txt' `
                    -OutFile (Join-Path $BugBountyRoot 'wordlists\resolvers.txt')

                if (Test-Path '.\keys.env') {
                    $dest = Join-Path $BugBountyRoot 'keys.env'
                    Move-Item '.\keys.env' $dest -Force
                    Invoke-Native icacls @($dest, '/inheritance:r', '/grant:r', "${env:USERNAME}:(R,W)") | Out-Null
                }
            }

            # VS Code Extensions
            Write-Step 'VS Code extensions'
            try {
                Install-VSCodeExtensions -Group $VSCodeGroups -Root $repoRoot
            } catch {
                Add-Log $false 'VS Code extensions' $_.Exception.Message
            }
        }

        # Dotfiles & Editor Configurations
        if (-not $SkipConfigs) {
            Write-Step 'Dotfiles configuration deployment'

            # Fonts installation
            Step 'Nerd Fonts installation' {
                $fontInstaller = $null
                foreach ($candidate in @(
                    (Join-Path $dotfilesRoot "fonts\install-fonts.ps1"),
                    (Join-Path $repoRoot "scripts\windows\install-fonts.ps1"),
                    (Join-Path $repoRoot "scripts\install-fonts.ps1"),
                    ".\install-fonts.ps1"
                )) {
                    if (Test-Path $candidate) {
                        $fontInstaller = $candidate
                        break
                    }
                }
                if ($fontInstaller) {
                    if ($WhatIfPreference) {
                        Write-Host "[WHATIF] powershell -ExecutionPolicy Bypass -File $fontInstaller" -ForegroundColor Yellow
                    } else {
                        & powershell -NoProfile -ExecutionPolicy Bypass -File $fontInstaller -Force
                    }
                } else {
                    Write-Host "install-fonts.ps1 not found, skipping." -ForegroundColor Yellow
                }
            }

            # WezTerm
            $weztermSrc = if (Test-Path (Join-Path $dotfilesRoot "wezterm\.wezterm.lua")) {
                Join-Path $dotfilesRoot "wezterm\.wezterm.lua"
            } elseif (Test-Path (Join-Path $repoRoot "wezterm\.wezterm.lua")) {
                Join-Path $repoRoot "wezterm\.wezterm.lua"
            } else { $null }
            if ($weztermSrc) {
                Deploy-Config $weztermSrc (Join-Path $HOME ".wezterm.lua")
            }

            # Neovim
            $nvimSrc = if (Test-Path (Join-Path $dotfilesRoot "nvim")) {
                Join-Path $dotfilesRoot "nvim"
            } elseif (Test-Path (Join-Path $repoRoot "nvim")) {
                Join-Path $repoRoot "nvim"
            } else { $null }
            if ($nvimSrc) {
                Deploy-Config $nvimSrc (Join-Path $env:LOCALAPPDATA "nvim")
            }

            # VS Code Settings & MCP
            $vscodeSrc = if (Test-Path (Join-Path $dotfilesRoot "vscode\settings.json")) {
                Join-Path $dotfilesRoot "vscode\settings.json"
            } elseif (Test-Path (Join-Path $dotfilesRoot "Vscode\User\settings.json")) {
                Join-Path $dotfilesRoot "Vscode\User\settings.json"
            } elseif (Test-Path (Join-Path $repoRoot "Vscode\User\settings.json")) {
                Join-Path $repoRoot "Vscode\User\settings.json"
            } else { $null }

            if ($vscodeSrc) {
                $codeUserDir = Join-Path $env:APPDATA "Code\User"
                Deploy-Config $vscodeSrc (Join-Path $codeUserDir "settings.json")

                $mcpSrc = Join-Path (Split-Path $vscodeSrc) "mcp.json"
                if (Test-Path $mcpSrc) {
                    Deploy-Config $mcpSrc (Join-Path $codeUserDir "mcp.json")
                }
            }

            # PowerShell Profile
            $profileSrc = if (Test-Path (Join-Path $dotfilesRoot "windows\WindowsPowerShell\Microsoft.PowerShell_profile.ps1")) {
                Join-Path $dotfilesRoot "windows\WindowsPowerShell\Microsoft.PowerShell_profile.ps1"
            } elseif (Test-Path (Join-Path $dotfilesRoot "powershell\profile.ps1")) {
                Join-Path $dotfilesRoot "powershell\profile.ps1"
            } else { $null }

            if ($profileSrc) {
                Step 'Deploy PowerShell $PROFILE' {
                    New-Item -ItemType Directory -Force -Path (Split-Path $PROFILE) | Out-Null
                    New-Item -ItemType SymbolicLink -Path $PROFILE -Target $profileSrc -Force | Out-Null
                }
            }

            # Registry import
            if ($RegistryMode) {
                Step "Registry import: $RegistryMode" {
                    Import-RegistryFiles -Root $repoRoot -Mode $RegistryMode
                }
            }

            # GNU Stow
            if ($Stow) {
                Step 'Deploy with GNU Stow' {
                    Invoke-StowAll -Root $repoRoot
                }
            }
        }
    }

    # ========================================================================
    # OPTIONAL - UPGRADES
    # ========================================================================
    if ($Upgrade -and $isAdmin) {
        Write-Step 'System upgrades'
        Step 'Windows Update' {
            Install-Module PSWindowsUpdate -Force -Scope AllUsers
            Get-WindowsUpdate -Install -AcceptAll -IgnoreReboot | Out-Null
        }
        Step 'Winget package upgrades' {
            Invoke-Native winget @('upgrade', '--all', '--silent', '--accept-package-agreements', '--accept-source-agreements') -OkCodes @(0, -1978335189)
        }
    }
}
catch {
    Add-Log $false "Installer execution" $_.Exception.Message
}
finally {
    if ($script:TemporaryRepository -and (Test-Path -LiteralPath $script:TemporaryRepository)) {
        Remove-Item -LiteralPath $script:TemporaryRepository -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ----------------------------------------------------------------------------
# Summary Report
# ----------------------------------------------------------------------------
Write-Host "`n=============================================" -ForegroundColor White
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
$script:Log | ForEach-Object {
    $c = if ($_ -like '[FAIL]*') { 'Red' }
         elseif ($_ -like '[SKIP]*' -or $_ -like '[WHATIF]*') { 'Yellow' }
         else { 'Green' }
    Write-Host $_ -ForegroundColor $c
}
Write-Host "---------------------------------------------"
if ($script:Fails -eq 0) {
    Write-Host "All done - no failures!" -ForegroundColor Green
} else {
    Write-Host "Completed with $($script:Fails) failure(s). Review log above." -ForegroundColor Yellow
}
Write-Host "NOTE: A system reboot is recommended to finalize WSL, Docker, Rust, and security baselines." -ForegroundColor Cyan
