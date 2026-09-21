[CmdletBinding()]
param(
    [switch]$SkipPackages,
    [switch]$SkipGit,
    [switch]$SkipNode,
    [switch]$SkipWsl,
    [switch]$SkipFonts,
    [switch]$SkipRegistry,
    [switch]$SkipStow,
    [ValidateSet("add", "remove")]
    [string]$RegistryMode = "add",
    [string]$FontsPath,
    [string]$StowTarget = $env:USERPROFILE,
    [switch]$ForceFonts
)

$ErrorActionPreference = "Stop"

$DotfilesDir = (Resolve-Path (Join-Path $PSScriptRoot "..\..")).Path

if (-not $FontsPath) {
    $FontsPath = Join-Path $DotfilesDir "windows\assets\fonts"
}

$Log = @()
$Fails = 0

function Write-Section {
    param(
        [string]$Message,
        [ConsoleColor]$Color = "Cyan"
    )

    Write-Host ""
    Write-Host "[windows-install] $Message" -ForegroundColor $Color
}

function Add-InstallLog {
    param(
        [string]$Status,
        [string]$Area,
        [string]$Message
    )

    $script:Log += "[{0}] [{1}] {2}" -f $Status, $Area, $Message
}

function Invoke-Step {
    param(
        [string]$Area,
        [string]$Label,
        [scriptblock]$Script
    )

    try {
        & $Script
        Add-InstallLog "OK" $Area $Label
    }
    catch {
        Add-InstallLog "FAIL" $Area "$Label - $($_.Exception.Message)"
        $script:Fails++
    }
}

function Invoke-Native {
    param(
        [string]$FilePath,
        [string[]]$ArgumentList
    )

    & $FilePath @ArgumentList
    if ($LASTEXITCODE -ne 0) {
        throw "$FilePath exited with code $LASTEXITCODE"
    }
}

function Test-IsAdministrator {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = [Security.Principal.WindowsPrincipal] $identity
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Import-DotEnv {
    $envFile = Join-Path $DotfilesDir ".env"
    if (-not (Test-Path -LiteralPath $envFile)) {
        return
    }

    Get-Content -LiteralPath $envFile | ForEach-Object {
        if ($_ -match "^\s*([^#=]+)=(.*)$") {
            $name = $matches[1].Trim()
            $value = $matches[2].Trim().Trim('"').Trim("'")
            Set-Item -Path "Env:$name" -Value $value
        }
    }
}

function Install-WingetPackage {
    param(
        [string]$Id,
        [string]$Label = $Id
    )

    Invoke-Step "winget" $Label {
        Invoke-Native "winget" @(
            "install",
            "--id", $Id,
            "--silent",
            "--accept-package-agreements",
            "--accept-source-agreements",
            "--no-upgrade",
            "-e"
        )
    }
}

function Install-ChocoPackage {
    param(
        [string]$Id,
        [string]$Label = $Id
    )

    Invoke-Step "choco" $Label {
        Invoke-Native "choco" @("install", $Id, "-y", "--no-progress")
    }
}

function Install-Chocolatey {
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Chocolatey already installed - skipping." -ForegroundColor Green
        Add-InstallLog "OK" "choco" "Chocolatey already present"
        return
    }

    Invoke-Step "choco" "Install Chocolatey" {
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        Invoke-Expression ((New-Object System.Net.WebClient).DownloadString("https://community.chocolatey.org/install.ps1"))
    }
}

function Install-Packages {
    Write-Section "Installing package managers and applications"
    Install-Chocolatey

    $wingetPackages = @(
        @{ Id = "Microsoft.VisualStudioCode"; Label = "VS Code" },
        @{ Id = "Microsoft.WindowsTerminal"; Label = "Windows Terminal" },
        @{ Id = "Git.Git"; Label = "Git" },
        @{ Id = "GitHub.cli"; Label = "GitHub CLI" },
        @{ Id = "Python.Python.3.12"; Label = "Python 3.12" },
        @{ Id = "OpenJS.NodeJS.LTS"; Label = "Node.js LTS" },
        @{ Id = "GoLang.Go"; Label = "Go" },
        @{ Id = "Rustlang.Rustup"; Label = "Rust" },
        @{ Id = "Docker.DockerDesktop"; Label = "Docker Desktop" },
        @{ Id = "JetBrains.Toolbox"; Label = "JetBrains Toolbox" },
        @{ Id = "Nmap.Nmap"; Label = "Nmap" },
        @{ Id = "WiresharkFoundation.Wireshark"; Label = "Wireshark" },
        @{ Id = "PortSwigger.BurpSuite.Community"; Label = "Burp Suite Community" }
    )

    foreach ($package in $wingetPackages) {
        Install-WingetPackage -Id $package.Id -Label $package.Label
    }

    $chocoPackages = @(
        @{ Id = "masscan"; Label = "Masscan" },
        @{ Id = "netcat"; Label = "Netcat" },
        @{ Id = "maltego"; Label = "Maltego" },
        @{ Id = "metasploit"; Label = "Metasploit" },
        @{ Id = "openvpn"; Label = "OpenVPN" }
    )

    foreach ($package in $chocoPackages) {
        Install-ChocoPackage -Id $package.Id -Label $package.Label
    }
}

function Set-GitConfiguration {
    Write-Section "Configuring Git"
    Import-DotEnv

    $gitUserName = $env:GIT_USER_NAME
    $gitUserEmail = $env:GIT_USER_EMAIL

    if (-not $gitUserName -or -not $gitUserEmail) {
        Add-InstallLog "FAIL" "git" "GIT_USER_NAME or GIT_USER_EMAIL is missing from environment or .env"
        $script:Fails++
        return
    }

    Invoke-Step "git" "Global config" {
        Invoke-Native "git" @("config", "--global", "user.name", $gitUserName)
        Invoke-Native "git" @("config", "--global", "user.email", $gitUserEmail)
        Invoke-Native "git" @("config", "--global", "core.autocrlf", "input")
        Invoke-Native "git" @("config", "--global", "init.defaultBranch", "main")
        Invoke-Native "git" @("config", "--global", "pull.rebase", "true")
    }
}

function Install-NodeTools {
    Write-Section "Installing Node.js global tools"

    Invoke-Step "node" "pnpm and yarn" {
        Invoke-Native "npm" @("install", "-g", "pnpm")
        Invoke-Native "npm" @("install", "-g", "yarn")
    }
}

function Install-Wsl {
    Write-Section "Setting up WSL"

    Invoke-Step "wsl" "Install and update WSL" {
        Invoke-Native "wsl" @("--install")
        Invoke-Native "wsl" @("--update")
    }
}

function Get-FontRegistrySuffix {
    param([string]$Extension)

    switch ($Extension.ToLowerInvariant()) {
        ".fon" { " (Font)" }
        ".otf" { " (OpenType)" }
        ".ttc" { " (TrueType Collection)" }
        default { " (TrueType)" }
    }
}

function Install-Fonts {
    param(
        [string]$SourcePath,
        [switch]$Force
    )

    Write-Section "Installing fonts"

    Invoke-Step "fonts" $SourcePath {
        if (-not (Test-Path -LiteralPath $SourcePath -PathType Container)) {
            throw "Fonts folder was not found: $SourcePath"
        }

        $supportedExtensions = @(".fon", ".otf", ".ttc", ".ttf")
        $fontsDirectory = Join-Path $env:LOCALAPPDATA "Microsoft\Windows\Fonts"
        $fontRegistryPath = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"

        New-Item -ItemType Directory -Path $fontsDirectory -Force | Out-Null
        New-Item -Path $fontRegistryPath -Force | Out-Null

        $fontFiles = Get-ChildItem -LiteralPath $SourcePath -Recurse -File |
            Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() }

        if (-not $fontFiles) {
            Write-Warning "No supported font files were found in $SourcePath"
            return
        }

        foreach ($font in $fontFiles) {
            $targetPath = Join-Path $fontsDirectory $font.Name
            $registryName = "{0}{1}" -f $font.BaseName, (Get-FontRegistrySuffix -Extension $font.Extension)

            if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
                Write-Host "Skipping existing font: $($font.Name)"
                continue
            }

            Copy-Item -LiteralPath $font.FullName -Destination $targetPath -Force:$Force
            New-ItemProperty -Path $fontRegistryPath -Name $registryName -Value $font.Name -PropertyType String -Force | Out-Null
            Write-Host "Installed font: $($font.Name)"
        }
    }
}

function Import-RegistryFiles {
    param([string]$Mode)

    Write-Section "Importing registry files: $Mode"

    Invoke-Step "registry" $Mode {
        $registryDir = Join-Path $DotfilesDir "windows\registry\$Mode"
        if (-not (Test-Path -LiteralPath $registryDir -PathType Container)) {
            throw "Registry folder was not found: $registryDir"
        }

        Get-ChildItem -LiteralPath $registryDir -Filter "*.reg" | Sort-Object Name | ForEach-Object {
            Write-Host "Importing $($_.Name)"
            Invoke-Native "reg" @("import", $_.FullName)
        }
    }
}

function Invoke-StowAll {
    param([string]$TargetDir)

    Write-Section "Stowing Windows dotfiles"

    Invoke-Step "stow" $TargetDir {
        if (-not (Get-Command stow -ErrorAction SilentlyContinue)) {
            throw "stow is required. Install GNU Stow for Windows before running this step."
        }

        $packageGlobs = @(
            "windows\assets\*",
            "windows\browser\*",
            "windows\editor\*",
            "windows\obsidian",
            "windows\security\*",
            "windows\shell",
            "windows\ssh",
            "windows\terminal\*",
            "windows\wallpaper",
            "windows\wsl"
        )

        foreach ($glob in $packageGlobs) {
            Get-ChildItem -Path (Join-Path $DotfilesDir $glob) -Directory -ErrorAction SilentlyContinue | ForEach-Object {
                if ($_.Name -eq "windows-terminal") {
                    Write-Host "Skipping windows-terminal; import windows\terminal\windows-terminal\settings.json manually."
                    return
                }

                $packageDir = Split-Path -Parent $_.FullName
                $packageName = Split-Path -Leaf $_.FullName
                $relativePath = $_.FullName.Replace($DotfilesDir, "").TrimStart("\")

                Write-Host "Stowing $packageName from $relativePath"
                Invoke-Native "stow" @("-d", $packageDir, "-t", $TargetDir, $packageName)
            }
        }
    }
}

Push-Location $DotfilesDir
try {
    if ((-not $SkipPackages -or -not $SkipWsl -or -not $SkipRegistry) -and -not (Test-IsAdministrator)) {
        throw "Run this script as Administrator, or skip admin-only steps with -SkipPackages -SkipWsl -SkipRegistry."
    }

    if (-not $SkipPackages) {
        Install-Packages
    }

    if (-not $SkipGit) {
        Set-GitConfiguration
    }

    if (-not $SkipNode) {
        Install-NodeTools
    }

    if (-not $SkipWsl) {
        Install-Wsl
    }

    if (-not $SkipFonts) {
        Install-Fonts -SourcePath $FontsPath -Force:$ForceFonts
    }

    if (-not $SkipRegistry) {
        Import-RegistryFiles -Mode $RegistryMode
    }

    if (-not $SkipStow) {
        Invoke-StowAll -TargetDir $StowTarget
    }
}
finally {
    Pop-Location
}

Write-Host ""
Write-Host "=============================================" -ForegroundColor White
Write-Host "  Windows Installation Summary" -ForegroundColor White
Write-Host "=============================================" -ForegroundColor White
$Log | ForEach-Object { Write-Host $_ }
Write-Host "---------------------------------------------"

if ($Fails -eq 0) {
    Write-Host "All done - no failures!" -ForegroundColor Green
}
else {
    Write-Host "Done with $Fails failure(s). Check the log above." -ForegroundColor Yellow
}

Write-Host "NOTE: Reboot recommended after Docker, WSL, Rust, font, or registry changes." -ForegroundColor Cyan

if ($Fails -gt 0) {
    exit 1
}
