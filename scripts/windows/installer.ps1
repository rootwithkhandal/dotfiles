# ============================================================
#  Dev Environment Installer
#  Run in an elevated (Admin) PowerShell session
# ============================================================

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$GitName,
    [string]$GitEmail,
    [switch]$SkipGitConfig,
    [switch]$SkipWSL,
    [switch]$SkipSecurityTools
)

$ErrorActionPreference = 'Stop'

# ── Admin check ──────────────────────────────────────────────

$isAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()
).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Error 'Please run this script as Administrator.'
    exit 1
}

# ── Logging helpers ──────────────────────────────────────────

$script:Log = [System.Collections.Generic.List[string]]::new()
$script:Fails = 0

function Write-Step {
    param([string]$Message)
    Write-Host "`n:: $Message" -ForegroundColor Cyan
}

function Add-LogEntry {
    param(
        [ValidateSet('OK', 'FAIL', 'SKIP')]
        [string]$Status,
        [string]$Source,
        [string]$Label,
        [string]$Detail
    )

    $prefix = switch ($Status) {
        'OK'   { '[OK]  ' }
        'FAIL' { '[FAIL]' }
        'SKIP' { '[SKIP]' }
    }

    $entry = "$prefix [$Source] $Label"
    if ($Detail) { $entry += " - $Detail" }
    $script:Log.Add($entry)

    if ($Status -eq 'FAIL') { $script:Fails++ }
}

# ── Package installer wrappers ───────────────────────────────

function Install-Winget {
    param([string]$Id, [string]$Label = $Id)

    # Skip if already installed (winget list is faster than a full install attempt).
    $existing = winget list --id $Id --exact --accept-source-agreements 2>&1 |
        Select-String -Pattern ([regex]::Escape($Id)) -Quiet

    if ($existing) {
        Add-LogEntry -Status OK -Source winget -Label $Label -Detail 'already installed'
        return
    }

    try {
        if ($PSCmdlet.ShouldProcess($Id, 'Install via winget')) {
            winget install --id $Id --silent --accept-package-agreements --accept-source-agreements --no-upgrade -e
            if ($LASTEXITCODE -ne 0) { throw "winget exited with code $LASTEXITCODE" }
            Add-LogEntry -Status OK -Source winget -Label $Label
        }
    }
    catch {
        Add-LogEntry -Status FAIL -Source winget -Label $Label -Detail $_.Exception.Message
    }
}

function Install-Choco {
    param([string]$Id, [string]$Label = $Id)

    # Skip if already installed.
    $existing = choco list --exact $Id --limit-output 2>&1 |
        Select-String -Pattern ([regex]::Escape($Id)) -Quiet

    if ($existing) {
        Add-LogEntry -Status OK -Source choco -Label $Label -Detail 'already installed'
        return
    }

    try {
        if ($PSCmdlet.ShouldProcess($Id, 'Install via Chocolatey')) {
            choco install $Id -y --no-progress 2>&1 | Out-Null
            if ($LASTEXITCODE -ne 0) { throw "choco exited with code $LASTEXITCODE" }
            Add-LogEntry -Status OK -Source choco -Label $Label
        }
    }
    catch {
        Add-LogEntry -Status FAIL -Source choco -Label $Label -Detail $_.Exception.Message
    }
}

# ── Chocolatey bootstrap ────────────────────────────────────

Write-Step 'Checking Chocolatey'

if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host 'Installing Chocolatey...' -ForegroundColor Yellow
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol =
        [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString(
        'https://community.chocolatey.org/install.ps1'))
    Add-LogEntry -Status OK -Source setup -Label 'Chocolatey installed'
}
else {
    Write-Host 'Chocolatey already installed.' -ForegroundColor Green
}

# ── Scoop (cannot install as Admin) ──────────────────────────

Write-Step 'Checking Scoop'

if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host 'SKIPPED: Scoop must be installed in a non-Admin PowerShell.' -ForegroundColor Yellow
    Write-Host '  Run: irm get.scoop.sh | iex' -ForegroundColor Yellow
    Add-LogEntry -Status SKIP -Source setup -Label 'Scoop' -Detail "run 'irm get.scoop.sh | iex' in non-Admin shell"
}
else {
    Write-Host 'Scoop already installed.' -ForegroundColor Green
    Add-LogEntry -Status OK -Source setup -Label 'Scoop already present'
}

# ── Dev Tools ────────────────────────────────────────────────

Write-Step 'Installing dev tools'

$devTools = @(
    @{ Id = 'Microsoft.VisualStudioCode';    Label = 'VS Code' }
    @{ Id = 'Microsoft.WindowsTerminal';     Label = 'Windows Terminal' }
    @{ Id = 'Git.Git';                       Label = 'Git' }
    @{ Id = 'GitHub.cli';                    Label = 'GitHub CLI' }
    @{ Id = 'Python.Python.3.12';            Label = 'Python 3.12' }
    @{ Id = 'OpenJS.NodeJS.LTS';             Label = 'Node.js LTS' }
    @{ Id = 'GoLang.Go';                     Label = 'Go' }
    @{ Id = 'Rustlang.Rustup';               Label = 'Rust' }
    @{ Id = 'Docker.DockerDesktop';           Label = 'Docker Desktop' }
    @{ Id = 'JetBrains.Toolbox';             Label = 'JetBrains Toolbox' }
)

foreach ($tool in $devTools) {
    Install-Winget -Id $tool.Id -Label $tool.Label
}

# ── Git Config ───────────────────────────────────────────────

if (-not $SkipGitConfig) {
    Write-Step 'Configuring Git'

    if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
        Add-LogEntry -Status SKIP -Source git -Label 'Git config' -Detail 'git not found in PATH (reboot may be needed)'
    }
    else {
        try {
            if ($GitName)  { git config --global user.name  $GitName }
            if ($GitEmail) { git config --global user.email $GitEmail }
            git config --global core.autocrlf input
            git config --global init.defaultBranch main
            git config --global pull.rebase true
            Add-LogEntry -Status OK -Source git -Label 'Git global config applied'
        }
        catch {
            Add-LogEntry -Status FAIL -Source git -Label 'Git config' -Detail $_.Exception.Message
        }
    }
}

# ── Node.js global packages ─────────────────────────────────

Write-Step 'Setting up Node.js global packages'

if (-not (Get-Command npm -ErrorAction SilentlyContinue)) {
    Add-LogEntry -Status SKIP -Source npm -Label 'Node global tools' -Detail 'npm not found in PATH (reboot may be needed)'
}
else {
    try {
        npm install -g pnpm yarn 2>&1 | Out-Null
        Add-LogEntry -Status OK -Source npm -Label 'pnpm + yarn installed globally'
    }
    catch {
        Add-LogEntry -Status FAIL -Source npm -Label 'Node global tools' -Detail $_.Exception.Message
    }
}

# ── Network & Recon ──────────────────────────────────────────

if (-not $SkipSecurityTools) {
    Write-Step 'Installing network/recon tools'

    Install-Winget 'Nmap.Nmap'                       'Nmap'
    Install-Winget 'WiresharkFoundation.Wireshark'   'Wireshark'
    Install-Choco  'masscan'                         'Masscan'
    Install-Choco  'netcat'                          'Netcat'

    # ── Security / Pentesting ────────────────────────────────

    Write-Step 'Installing security tools'

    Install-Winget 'PortSwigger.BurpSuite.Community' 'Burp Suite Community'
    Install-Choco  'maltego'                         'Maltego'
    Install-Choco  'metasploit'                      'Metasploit'
    Install-Choco  'openvpn'                         'OpenVPN'
}
else {
    Add-LogEntry -Status SKIP -Source setup -Label 'Security/network tools' -Detail 'skipped via -SkipSecurityTools'
}

# ── WSL ──────────────────────────────────────────────────────

if (-not $SkipWSL) {
    Write-Step 'Setting up WSL'

    try {
        # wsl --install
        # wsl --install -d kali-linux
        # wsl --install -d Ubuntu
        wsl --update 2>&1 | Out-Null
        Add-LogEntry -Status OK -Source wsl -Label 'WSL updated'
    }
    catch {
        Add-LogEntry -Status FAIL -Source wsl -Label 'WSL' -Detail $_.Exception.Message
    }
}
else {
    Add-LogEntry -Status SKIP -Source wsl -Label 'WSL' -Detail 'skipped via -SkipWSL'
}

# ── Summary ──────────────────────────────────────────────────

Write-Host ''
Write-Host '=============================================' -ForegroundColor White
Write-Host '  Installation Summary' -ForegroundColor White
Write-Host '=============================================' -ForegroundColor White
$script:Log | ForEach-Object { Write-Host $_ }
Write-Host '---------------------------------------------'

if ($Fails -eq 0) {
    Write-Host 'All done - no failures!' -ForegroundColor Green
}
else {
    Write-Host "Done with $Fails failure(s). Check the log above." -ForegroundColor Yellow
}

Write-Host 'NOTE: Reboot recommended to finalise Docker, WSL, and Rust.' -ForegroundColor Cyan

if ($Fails -gt 0) { exit 1 }
