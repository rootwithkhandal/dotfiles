# Dotfiles Installer for Windows (merged)
# Run in an elevated PowerShell session

$ErrorActionPreference = "Stop"

function Write-Host-Color($Message, $Color = "Cyan") {
    Write-Host "`n[installer] $Message" -ForegroundColor $Color
}

# Ensure running as Administrator
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit 1
}

# Logging helpers
$Log = @()
$Fails = 0

function Install-Winget { param([string]$Id, [string]$Label = $Id)
    try {
        winget install --id $Id --silent --accept-package-agreements --accept-source-agreements --no-upgrade -e
        $script:Log += "[OK]  [winget] $Label"
    } catch {
        $script:Log += "[FAIL][winget] $Label - " + $_.Exception.Message
        $script:Fails++
    }
}

function Install-Choco { param([string]$Id, [string]$Label = $Id)
    try {
        choco install $Id -y --no-progress > $null
        $script:Log += "[OK]  [choco ] $Label"
    } catch {
        $script:Log += "[FAIL][choco ] $Label - " + $_.Exception.Message
        $script:Fails++
    }
}

# -------------------------------------------------------------------
# 1. Install system tools (winget, chocolatey packages)
# -------------------------------------------------------------------
# Install Chocolatey if missing
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey already installed - skipping." -ForegroundColor Green
}

# Install dev tools via winget
Write-Host "\nInstalling dev tools..." -ForegroundColor Cyan
Install-Winget "Microsoft.VisualStudioCode"      "VS Code"
Install-Winget "Microsoft.WindowsTerminal"       "Windows Terminal"
Install-Winget "Git.Git"                         "Git"
Install-Winget "GitHub.cli"                      "GitHub CLI"
Install-Winget "Python.Python.3.12"              "Python 3.12"
Install-Winget "OpenJS.NodeJS.LTS"               "Node.js LTS"
Install-Winget "GoLang.Go"                       "Go"
Install-Winget "Rustlang.Rustup"                 "Rust"
Install-Winget "Docker.DockerDesktop"            "Docker Desktop"
Install-Winget "JetBrains.Toolbox"               "JetBrains Toolbox"

# Git global configuration
Write-Host "\nConfiguring Git..." -ForegroundColor Cyan
try {
    # Load credentials from .env if present
if (Test-Path ".env") {
    Get-Content ".env" | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim()
            Set-Item -Path "Env:$name" -Value $value
        }
    }
}
$gitUserName = $env:GIT_USER_NAME
$gitUserEmail = $env:GIT_USER_EMAIL
if (-not $gitUserName -or -not $gitUserEmail) {
    Write-Error "GIT_USER_NAME or GIT_USER_EMAIL not set in environment or .env file."
    exit 1
}
git config --global user.name  $gitUserName
git config --global user.email $gitUserEmail
    git config --global core.autocrlf input
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    $Log += "[OK]  Git global config applied"
} catch {
    $Log += "[FAIL] Git config - " + $_.Exception.Message
    $Fails++
}

# Node.js global packages
Write-Host "\nSetting up Node.js extras..." -ForegroundColor Cyan
try {
    npm install -g pnpm
    npm install -g yarn
    $Log += "[OK]  pnpm + yarn installed globally"
} catch {
    $Log += "[FAIL] Node global tools - " + $_.Exception.Message
    $Fails++
}

# Network & Recon tools
Write-Host "\nInstalling network/recon tools..." -ForegroundColor Cyan
Install-Winget "Nmap.Nmap"                       "Nmap"
Install-Winget "WiresharkFoundation.Wireshark"   "Wireshark"
Install-Choco  "masscan"                         "Masscan"
Install-Choco  "netcat"                          "Netcat"

# Security / Pentesting tools
Write-Host "\nInstalling security tools..." -ForegroundColor Cyan
Install-Winget "PortSwigger.BurpSuite.Community" "Burp Suite Community"
Install-Choco  "maltego"                         "Maltego"
Install-Choco  "metasploit"                      "Metasploit"
Install-Choco  "openvpn"                         "OpenVPN"

# WSL setup
Write-Host "\nSetting up WSL..." -ForegroundColor Cyan
try {
    wsl --install
    # wsl --install -d kali-linux
    # wsl --install -d Ubuntu
    wsl --update
    $Log += "[OK]  WSL + Kali + Ubuntu installed"
} catch {
    $Log += "[FAIL] WSL - " + $_.Exception.Message
    $Fails++
}

# -------------------------------------------------------------------
# 2. Install fonts and editor configurations
# -------------------------------------------------------------------
# Fonts
if (Test-Path "scripts/install-fonts.ps1") {
    Write-Host-Color "Installing fonts..." "Yellow"
    powershell -ExecutionPolicy Bypass -File "scripts/install-fonts.ps1" -Force
} else {
    Write-Host-Color "install-fonts.ps1 not found, skipping font installation." "Red"
}

# WezTerm configuration
if (Test-Path ".\wezterm\.wezterm.lua") {
    Write-Host-Color "Installing WezTerm configuration..." "Yellow"
    $weztermDest = Join-Path $HOME ".wezterm.lua"
    Copy-Item ".\wezterm\.wezterm.lua" $weztermDest -Force
    Write-Host "Done: $weztermDest" -ForegroundColor Green
} else {
    Write-Host-Color "WezTerm config not found, skipping." "Red"
}

# Neovim configuration
if (Test-Path ".\nvim") {
    Write-Host-Color "Installing Neovim configuration..." "Yellow"
    $nvimDest = Join-Path $env:LOCALAPPDATA "nvim"
    if (Test-Path $nvimDest) {
        Write-Host "Removing existing Neovim config at $nvimDest" -ForegroundColor Gray
        Remove-Item $nvimDest -Recurse -Force
    }
    Copy-Item ".\nvim" $nvimDest -Recurse -Force
    Write-Host "Done: $nvimDest" -ForegroundColor Green
} else {
    Write-Host-Color "Neovim config not found, skipping." "Red"
}

# VS Code configuration
if (Test-Path ".\Vscode\User\settings.json") {
    Write-Host-Color "Installing VS Code configuration..." "Yellow"
    $vscodeDestDir = Join-Path $env:APPDATA "Code\User"
    if (-not (Test-Path $vscodeDestDir)) {
        New-Item -ItemType Directory -Path $vscodeDestDir -Force | Out-Null
    }
    $vscodeDest = Join-Path $vscodeDestDir "settings.json"
    Copy-Item ".\Vscode\User\settings.json" $vscodeDest -Force
    Write-Host "Done: $vscodeDest" -ForegroundColor Green
} else {
    Write-Host-Color "VS Code config not found, skipping." "Red"
}

# -------------------------------------------------------------------
# 3. Final summary
# -------------------------------------------------------------------
Write-Host-Color "All configurations installed successfully!" "Green"
Write-Host "Note: Neovim will install plugins on its first launch." -ForegroundColor Gray

Write-Host "\n=============================================" -ForegroundColor White
Write-Host "  Installation Summary" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
$Log | ForEach-Object { Write-Host $_ }
Write-Host "---------------------------------------------"
if ($Fails -eq 0) {
    Write-Host "All done - no failures!" -ForegroundColor Green
} else {
    Write-Host "Done with $Fails failure(s). Check the log above." -ForegroundColor Yellow
}
Write-Host "NOTE: Reboot recommended to finalise Docker, WSL, and Rust." -ForegroundColor Cyan
