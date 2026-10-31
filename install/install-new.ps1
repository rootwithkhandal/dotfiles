<#
.SYNOPSIS
    Bootstrap this dotfiles repository on Windows.

.DESCRIPTION
    This script can be run from a checkout or streamed directly:

        irm https://raw.githubusercontent.com/rootwithkhandal/dotfiles/main/install.ps1 | iex

    When streamed, the repository is cloned to a temporary directory so that
    repository-relative configuration files are still available.

.PARAMETER RepositoryPath
    Existing dotfiles checkout to use. If omitted, the current script directory
    is used when available; streamed execution clones the repository.

.PARAMETER SkipPackages
    Do not install applications with winget.

.PARAMETER SkipModules
    Do not install PowerShell modules.

.PARAMETER SkipConfigs
    Do not copy editor and terminal configuration files.

.PARAMETER Security
    Apply the optional Windows security baseline. This changes firewall,
    networking, Defender, and audit settings and may require a reboot.

.PARAMETER WhatIf
    Show the actions that would be taken without changing the system.
#>

[CmdletBinding(SupportsShouldProcess)]
param(
    [string]$RepositoryPath,
    [string]$RepositoryUrl = "https://github.com/rootwithkhandal/dotfiles.git",
    [switch]$SkipPackages,
    [switch]$SkipModules,
    [switch]$SkipConfigs,
    [switch]$Security
)

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$script:Failures = [System.Collections.Generic.List[string]]::new()
$script:TemporaryRepository = $null

function Write-Section {
    param([Parameter(Mandatory)][string]$Message)

    Write-Host "`n== $Message ==" -ForegroundColor Cyan
}

function Write-Result {
    param(
        [Parameter(Mandatory)][string]$Message,
        [switch]$Failure
    )

    $color = if ($Failure) { "Red" } else { "Green" }
    Write-Host $Message -ForegroundColor $color
}

function Add-Failure {
    param(
        [Parameter(Mandatory)][string]$Step,
        [Parameter(Mandatory)][System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    $message = "${Step}: $($ErrorRecord.Exception.Message)"
    $script:Failures.Add($message)
    Write-Result "[FAIL] $message" -Failure
}

function Invoke-Step {
    param(
        [Parameter(Mandatory)][string]$Name,
        [Parameter(Mandatory)][scriptblock]$Action
    )

    try {
        if ($WhatIfPreference) {
            Write-Host "[WHATIF] $Name" -ForegroundColor Yellow
            return
        }

        & $Action
        Write-Result "[OK]   $Name"
    }
    catch {
        Add-Failure -Step $Name -ErrorRecord $_
    }
}

function Test-Administrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal]$identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Assert-Command {
    param([Parameter(Mandatory)][string]$Name)

    if (-not (Get-Command $Name -ErrorAction SilentlyContinue)) {
        throw "Required command '$Name' was not found."
    }
}

function Resolve-Repository {
    if ($RepositoryPath) {
        $resolved = (Resolve-Path -LiteralPath $RepositoryPath -ErrorAction Stop).Path
        if (-not (Test-Path -LiteralPath (Join-Path $resolved "README.md"))) {
            throw "RepositoryPath does not appear to be a dotfiles checkout: $resolved"
        }
        return $resolved
    }

    if ($PSScriptRoot -and (Test-Path -LiteralPath (Join-Path $PSScriptRoot "README.md"))) {
        return $PSScriptRoot
    }

    Assert-Command -Name "git"
    $script:TemporaryRepository = Join-Path ([System.IO.Path]::GetTempPath()) "dotfiles-install-$([guid]::NewGuid())"
    Invoke-Step -Name "Clone dotfiles repository" -Action {
        & git clone --depth 1 -- $RepositoryUrl $script:TemporaryRepository
        if ($LASTEXITCODE -ne 0) {
            throw "git clone exited with code $LASTEXITCODE."
        }
    }

    if ($script:Failures.Count -gt 0) {
        throw "The dotfiles repository could not be cloned."
    }
    return $script:TemporaryRepository
}

function Install-WingetPackages {
    param([Parameter(Mandatory)][string[]]$Packages)

    Assert-Command -Name "winget"
    foreach ($package in $Packages) {
        Invoke-Step -Name "Install $package" -Action {
            & winget install --id $package --exact --silent `
                --accept-package-agreements --accept-source-agreements
            if ($LASTEXITCODE -ne 0) {
                throw "winget exited with code $LASTEXITCODE."
            }
        }
    }
}

function Install-PowerShellModules {
    $modules = @("PSReadLine", "Terminal-Icons", "posh-git", "PSFzf")
    foreach ($module in $modules) {
        Invoke-Step -Name "Install PowerShell module $module" -Action {
            Install-Module -Name $module -Scope CurrentUser -Force -AllowClobber
        }
    }
}

function Install-Configurations {
    param([Parameter(Mandatory)][string]$Root)

    $configRoot = $Root
    $nestedConfigRoot = Join-Path $Root "dotfiles"
    if (Test-Path -LiteralPath (Join-Path $nestedConfigRoot "nvim")) {
        $configRoot = $nestedConfigRoot
    }

    $weztermSource = Join-Path $configRoot "wezterm\.wezterm.lua"
    if (Test-Path -LiteralPath $weztermSource) {
        Invoke-Step -Name "Install WezTerm configuration" -Action {
            Copy-Item -LiteralPath $weztermSource -Destination (Join-Path $HOME ".wezterm.lua") -Force
        }
    }

    $nvimSource = Join-Path $configRoot "nvim"
    if (Test-Path -LiteralPath $nvimSource) {
        Invoke-Step -Name "Install Neovim configuration" -Action {
            $destination = Join-Path $env:LOCALAPPDATA "nvim"
            if (Test-Path -LiteralPath $destination) {
                Remove-Item -LiteralPath $destination -Recurse -Force
            }
            Copy-Item -LiteralPath $nvimSource -Destination $destination -Recurse -Force
        }
    }

    $vscodeSource = Join-Path $configRoot "Vscode\User\settings.json"
    if (Test-Path -LiteralPath $vscodeSource) {
        Invoke-Step -Name "Install VS Code settings" -Action {
            $destinationDirectory = Join-Path $env:APPDATA "Code\User"
            New-Item -ItemType Directory -Path $destinationDirectory -Force | Out-Null
            Copy-Item -LiteralPath $vscodeSource `
                -Destination (Join-Path $destinationDirectory "settings.json") -Force
        }
    }

    $fontInstaller = Join-Path $Root "scripts\windows\install-fonts.ps1"
    if (-not (Test-Path -LiteralPath $fontInstaller)) {
        $fontInstaller = Join-Path $configRoot "scripts\windows\install-fonts.ps1"
    }
    if (Test-Path -LiteralPath $fontInstaller) {
        Invoke-Step -Name "Install fonts" -Action {
            & powershell.exe -NoProfile -ExecutionPolicy Bypass -File $fontInstaller -Force
            if ($LASTEXITCODE -ne 0) {
                throw "Font installer exited with code $LASTEXITCODE."
            }
        }
    }
}

function Set-GitDefaults {
    $settings = @{
        "init.defaultBranch" = "main"
        "core.autocrlf"      = "input"
        "credential.helper"  = "manager"
    }

    foreach ($setting in $settings.GetEnumerator()) {
        Invoke-Step -Name "Set Git $($setting.Key)" -Action {
            & git config --global $setting.Key $setting.Value
            if ($LASTEXITCODE -ne 0) {
                throw "git config exited with code $LASTEXITCODE."
            }
        }
    }
}

function Set-SecurityBaseline {
    if (-not (Test-Administrator)) {
        throw "The -Security switch requires an elevated PowerShell session."
    }

    Invoke-Step -Name "Enable Windows Firewall" -Action {
        Set-NetFirewallProfile -Profile Domain,Public,Private -Enabled True `
            -DefaultInboundAction Block -DefaultOutboundAction Allow
    }
    Invoke-Step -Name "Disable SMBv1" -Action {
        Disable-WindowsOptionalFeature -Online -FeatureName SMB1Protocol -NoRestart
    }
    Invoke-Step -Name "Disable LLMNR" -Action {
        $path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows NT\DNSClient"
        New-Item -Path $path -Force | Out-Null
        Set-ItemProperty -Path $path -Name "EnableMulticast" -Value 0 -Type DWord
    }
    Invoke-Step -Name "Disable Remote Desktop connections" -Action {
        Set-ItemProperty `
            -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" `
            -Name "fDenyTSConnections" -Value 1 -Type DWord
    }
}

function Invoke-Installer {
    $root = Resolve-Repository
    Write-Host "Using dotfiles repository: $root" -ForegroundColor Gray

    if (-not (Test-Administrator) -and (-not $SkipPackages -or $Security)) {
        throw "Run PowerShell as Administrator for package installation or -Security, or use -SkipPackages."
    }

    if (-not $SkipPackages) {
        Write-Section "Applications"
        Install-WingetPackages -Packages @(
            "Git.Git",
            "GitHub.cli",
            "Microsoft.VisualStudioCode",
            "Microsoft.WindowsTerminal",
            "Python.Python.3.12",
            "OpenJS.NodeJS.LTS",
            "GoLang.Go",
            "Rustlang.Rustup",
            "Neovim.Neovim"
        )
    }

    if (-not $SkipModules) {
        Write-Section "PowerShell modules"
        Install-PowerShellModules
    }

    Write-Section "Git defaults"
    Assert-Command -Name "git"
    Set-GitDefaults

    if (-not $SkipConfigs) {
        Write-Section "Dotfiles"
        Install-Configurations -Root $root
    }

    if ($Security) {
        Write-Section "Security baseline"
        Set-SecurityBaseline
    }
}

try {
    Invoke-Installer
}
catch {
    Add-Failure -Step "Installer" -ErrorRecord $_
}
finally {
    if ($script:TemporaryRepository -and (Test-Path -LiteralPath $script:TemporaryRepository)) {
        Remove-Item -LiteralPath $script:TemporaryRepository -Recurse -Force
    }
}

if ($script:Failures.Count -gt 0) {
    Write-Host "`nCompleted with $($script:Failures.Count) failure(s):" -ForegroundColor Yellow
    $script:Failures | ForEach-Object { Write-Host " - $_" -ForegroundColor Yellow }
    throw "Dotfiles installation completed with failures."
}

Write-Host "`nInstallation completed successfully." -ForegroundColor Green
