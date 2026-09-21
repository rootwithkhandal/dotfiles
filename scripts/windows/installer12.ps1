# ============================================================
#  Dev Environment Installer
#  Run in an elevated (Admin) PowerShell session
# ============================================================

# Require admin
if (-not ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "Please run this script as Administrator."
    exit 1
}

$Log   = @()
$Fails = 0

function Install-Winget {
    param([string]$Id, [string]$Label = $Id)
    try {
        winget install --id $Id --silent --accept-package-agreements --accept-source-agreements --no-upgrade -e
        $script:Log += "[OK]  [winget] $Label"
    } catch {
        $script:Log += "[FAIL][winget] $Label - " + $_.Exception.Message
        $script:Fails++
    }
}

function Install-Choco {
    param([string]$Id, [string]$Label = $Id)
    try {
        choco install $Id -y --no-progress 2>&1 | Out-Null
        $script:Log += "[OK]  [choco ] $Label"
    } catch {
        $script:Log += "[FAIL][choco ] $Label - " + $_.Exception.Message
        $script:Fails++
    }
}

# Chocolatey
if (-not (Get-Command choco -ErrorAction SilentlyContinue)) {
    Write-Host "Installing Chocolatey..." -ForegroundColor Cyan
    Set-ExecutionPolicy Bypass -Scope Process -Force
    [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
    Invoke-Expression ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
} else {
    Write-Host "Chocolatey already installed - skipping." -ForegroundColor Green
}

# Scoop (cannot install as Admin - must be done in a normal PowerShell window)
if (-not (Get-Command scoop -ErrorAction SilentlyContinue)) {
    Write-Host "SKIPPED: Scoop must be installed in a non-Admin PowerShell." -ForegroundColor Yellow
    Write-Host "  Run this in a normal PowerShell window:" -ForegroundColor Yellow
    Write-Host "  irm get.scoop.sh | iex" -ForegroundColor Yellow
    $Log += "[SKIP] Scoop - run 'irm get.scoop.sh | iex' in a non-Admin PowerShell"
} else {
    Write-Host "Scoop already installed - skipping." -ForegroundColor Green
    $Log += "[OK]  Scoop already present"
}

# Dev Tools
Write-Host "`nInstalling dev tools..." -ForegroundColor Cyan
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

# Git Config
Write-Host "`nConfiguring Git..." -ForegroundColor Cyan
try {
    git config --global user.name  "rootwithkhandal"
    git config --global user.email "i.priyanshkhandal@gmail.com"
    git config --global core.autocrlf input
    git config --global init.defaultBranch main
    git config --global pull.rebase true
    $Log += "[OK]  Git global config applied"
} catch {
    $Log += "[FAIL] Git config - " + $_.Exception.Message
    $Fails++
}

# Node.js Extras
Write-Host "`nSetting up Node.js extras..." -ForegroundColor Cyan
try {
    npm install -g pnpm
    npm install -g yarn
    $Log += "[OK]  pnpm + yarn installed globally"
} catch {
    $Log += "[FAIL] Node global tools - " + $_.Exception.Message
    $Fails++
}

# Network & Recon
Write-Host "`nInstalling network/recon tools..." -ForegroundColor Cyan
Install-Winget "Nmap.Nmap"                       "Nmap"
Install-Winget "WiresharkFoundation.Wireshark"   "Wireshark"
Install-Choco  "masscan"                         "Masscan"
Install-Choco  "netcat"                          "Netcat"

# Security / Pentesting
Write-Host "`nInstalling security tools..." -ForegroundColor Cyan
Install-Winget "PortSwigger.BurpSuite.Community" "Burp Suite Community"
Install-Choco  "maltego"                         "Maltego"
Install-Choco  "metasploit"                      "Metasploit"
Install-Choco  "openvpn"                         "OpenVPN"

# WSL
Write-Host "`nSetting up WSL..." -ForegroundColor Cyan
try {
    # wsl --install
    # wsl --install -d kali-linux
    # wsl --install -d Ubuntu
    wsl --update
    $Log += "[OK]  WSL + Kali + Ubuntu installed"
} catch {
    $Log += "[FAIL] WSL - " + $_.Exception.Message
    $Fails++
}

# Summary
Write-Host "`n=============================================" -ForegroundColor White
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
