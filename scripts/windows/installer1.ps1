# Dotfiles Installer for Windows
# This script automates the installation of WezTerm, Neovim, and VS Code configurations.

$ErrorActionPreference = "Stop"

function Write-Host-Color($Message, $Color = "Cyan") {
    Write-Host "`n[installer] $Message" -ForegroundColor $Color
}

try {
    # 1. Install Fonts
    if (Test-Path ".\install-fonts.ps1") {
        Write-Host-Color "Installing fonts..." "Yellow"
        powershell -ExecutionPolicy Bypass -File .\install-fonts.ps1 -Force
    } else {
        Write-Host-Color "install-fonts.ps1 not found, skipping font installation." "Red"
    }

    # 2. WezTerm Configuration
    if (Test-Path ".\wezterm\.wezterm.lua") {
        Write-Host-Color "Installing WezTerm configuration..." "Yellow"
        $weztermDest = Join-Path $HOME ".wezterm.lua"
        Copy-Item ".\wezterm\.wezterm.lua" $weztermDest -Force
        Write-Host "Done: $weztermDest" -ForegroundColor Green
    }

    # 3. Neovim Configuration
    if (Test-Path ".\nvim") {
        Write-Host-Color "Installing Neovim configuration..." "Yellow"
        $nvimDest = Join-Path $env:LOCALAPPDATA "nvim"
        if (Test-Path $nvimDest) {
            Write-Host "Removing existing Neovim config at $nvimDest" -ForegroundColor Gray
            Remove-Item $nvimDest -Recurse -Force
        }
        Copy-Item ".\nvim" $nvimDest -Recurse -Force
        Write-Host "Done: $nvimDest" -ForegroundColor Green
    }

    # 4. VS Code Configuration
    if (Test-Path ".\Vscode\User\settings.json") {
        Write-Host-Color "Installing VS Code configuration..." "Yellow"
        $vscodeDestDir = Join-Path $env:APPDATA "Code\User"
        if (-not (Test-Path $vscodeDestDir)) {
            New-Item -ItemType Directory -Path $vscodeDestDir -Force | Out-Null
        }
        $vscodeDest = Join-Path $vscodeDestDir "settings.json"
        Copy-Item ".\Vscode\User\settings.json" $vscodeDest -Force
        Write-Host "Done: $vscodeDest" -ForegroundColor Green
    }

    Write-Host-Color "All configurations installed successfully!" "Green"
    Write-Host "Note: Neovim will install plugins on its first launch." -ForegroundColor Gray

} catch {
    Write-Host-Color "Installation failed: $($_.Exception.Message)" "Red"
    exit 1
}
