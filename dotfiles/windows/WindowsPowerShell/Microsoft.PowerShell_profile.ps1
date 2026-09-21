# ── Startup & Admin Detection ─────────────────────────────────

$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$adminSuffix = if ($isAdmin) { " [ADMIN]" } else { "" }
$Host.UI.RawUI.WindowTitle = "PowerShell {0}$adminSuffix" -f $PSVersionTable.PSVersion.ToString()


# ── Helpers ───────────────────────────────────────────────────

function Test-CommandExists {
    param($command)
    $null -ne (Get-Command $command -ErrorAction SilentlyContinue)
}


# ── Module Imports ────────────────────────────────────────────

# File icons in directory listings
if (-not (Get-Module -ListAvailable -Name Terminal-Icons)) {
    Install-Module -Name Terminal-Icons -Scope CurrentUser -Force -SkipPublisherCheck
}

Import-Module -Name Terminal-Icons -ErrorAction SilentlyContinue

# System info banner (adds ~1s to startup; remove if speed matters)
# Import-Module windows-screenfetch -ErrorAction SilentlyContinue

# Chocolatey tab-completion
$ChocolateyProfile = "$env:ChocolateyInstall\helpers\chocolateyProfile.psm1"
if (Test-Path $ChocolateyProfile) {
    Import-Module "$ChocolateyProfile"
}


# ── Oh-My-Posh ────────────────────────────────────────────────

$ENV:POSH_THEMES_PATH = "C:\Users\nyx\Documents\WindowsPowerShell"
# example : oh-my-posh init pwsh --config https://raw.githubusercontent.com/JanDeDobbeleer/oh-my-posh/main/themes/cobalt2.omp.json | Invoke-Expression

oh-my-posh init pwsh --config "$env:POSH_THEMES_PATH\posh-config.json" | Invoke-Expression

# ── Starship ──────────────────────────────────────────────────
# Invoke-Expression (&starship init powershell)
# $ENV:STARSHIP_CONFIG = "C:\Users\xphantom\Documents\WindowsPowerShell\starship.toml"


# ── Editor Configuration ──────────────────────────────────────

$EDITOR = if (Test-CommandExists code)          { 'code' }
          elseif (Test-CommandExists zed)        { 'zed' }
          elseif (Test-CommandExists nvim)       { 'nvim' }
          elseif (Test-CommandExists notepad++)  { 'notepad++' }
          else                                  { 'notepad' }
$env:EDITOR = $EDITOR

function Edit-Profile { & $EDITOR $PROFILE }
Set-Alias -Name ep -Value Edit-Profile

function reload-profile { & $PROFILE }


# ── PSReadLine ────────────────────────────────────────────────

# Predictive IntelliSense requires PSReadLine 2.2+ (PowerShell 7)
$psrlVersion = (Get-Module PSReadLine).Version
if ($psrlVersion -and $psrlVersion -ge [version]"2.2.0") {
    Set-PSReadLineOption -PredictionSource History
    Set-PSReadLineOption -PredictionViewStyle ListView
}
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
Set-PSReadLineOption -Colors @{
    Command   = 'Yellow'
    Parameter = 'Green'
    String    = 'DarkCyan'
}


# ── Navigation ────────────────────────────────────────────────

function docs  { Set-Location -Path $HOME\Documents }
function dtop  { Set-Location -Path $HOME\Desktop }

function mkcd($path) {
    New-Item -ItemType Directory -Path $path -Force | Out-Null
    Set-Location $path
}

# Open current folder in VS Code
function c. { code . }


# ── File Utilities ────────────────────────────────────────────

function touch($file) { "" | Out-File $file -Encoding ASCII }

function nf { param($name) New-Item -ItemType "file" -Path . -Name $name }

function ff($name) {
    # Recursive fuzzy file finder
    Get-ChildItem -Recurse -Filter "*${name}*" -ErrorAction SilentlyContinue | ForEach-Object {
        Write-Output "$($_.Directory)\$($_)"
    }
}

function which($name) {
    Get-Command $name | Select-Object -ExpandProperty Definition
}

function whichdir($name) {
    Split-Path -Parent (Get-Command $name | Select-Object -ExpandProperty Definition)
}

function unzip($file) {
    Write-Output "Extracting $file to $pwd"
    $fullFile = Get-ChildItem -Path $pwd -Filter $file | ForEach-Object { $_.FullName }
    Expand-Archive -Path $fullFile -DestinationPath $pwd
}

function grep($regex, $dir) {
    if ($dir) {
        Get-ChildItem $dir | Select-String $regex
        return
    }
    $input | Select-String $regex
}

function sed($file, $find, $replace) {
    (Get-Content $file).Replace("$find", $replace) | Set-Content $file
}

function head {
    param($Path, $n = 10)
    Get-Content $Path -Head $n
}

function tail {
    param($Path, $n = 10)
    Get-Content $Path -Tail $n
}

# Enhanced directory listings
function la { Get-ChildItem -Path . -Force | Format-Table -AutoSize }
function ll { Get-ChildItem -Path . -Force -Hidden | Format-Table -AutoSize }

# Disk usage
function df { Get-Volume }


# ── Git Shortcuts ─────────────────────────────────────────────

function gs  { git status }
function ga  { git add . }
function gcm { param($m) git commit -m "$m" }       # git commit (avoids shadowing Get-Content)
function gp  { git push }
function gcl($repo) { git clone $repo }              # git clone (renamed from gc to avoid conflict)

function gcom {
    git add .
    git commit -m "$($args -join ' ')"
}

function lazyg {
    git add .
    git commit -m "$($args -join ' ')"
    git push
}

function lazymain {
    git add .
    git commit -m "$($args -join ' ')"
    git push -u origin main
}


# ── System Utilities ──────────────────────────────────────────

function sysinfo { Get-ComputerInfo }

function uptime {
    if ($PSVersionTable.PSVersion.Major -eq 5) {
        Get-WmiObject win32_operatingsystem |
            Select-Object @{Name='LastBootUpTime'; Expression={$_.ConverttoDateTime($_.lastbootuptime)}} |
            Format-Table -HideTableHeaders
    } else {
        net statistics workstation | Select-String "since" | ForEach-Object { $_.ToString().Replace('Statistics since ', '') }
    }
}

function export($name, $value) {
    Set-Item -Force -Path "env:$name" -Value $value
}

function Update-PowerShell {
    try {
        Write-Host "Checking for PowerShell updates..." -ForegroundColor Cyan
        $currentVersion = $PSVersionTable.PSVersion.ToString()
        $latestReleaseInfo = Invoke-RestMethod -Uri "https://api.github.com/repos/PowerShell/PowerShell/releases/latest"
        $latestVersion = $latestReleaseInfo.tag_name.Trim('v')
        if ($currentVersion -lt $latestVersion) {
            Write-Host "Updating PowerShell..." -ForegroundColor Yellow
            winget upgrade "Microsoft.PowerShell" --accept-source-agreements --accept-package-agreements
            Write-Host "PowerShell has been updated. Please restart your shell to reflect changes." -ForegroundColor Magenta
        } else {
            Write-Host "Your PowerShell is up to date." -ForegroundColor Green
        }
    } catch {
        Write-Error "Failed to update PowerShell. Error: $_"
    }
}

function png2jpg {
    param(
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$Path,

        [int]$Quality = 90,

        [switch]$DeleteOriginal
    )

    & "C:\Users\nyx\Documents\WindowsPowerShell\custom-scripts\png2jpg.ps1" -Path $Path -Quality $Quality -DeleteOriginal:$DeleteOriginal
}

# ── Network Utilities ─────────────────────────────────────────

function Get-PubIP { (Invoke-WebRequest http://ifconfig.me/ip).Content }

function flushdns { Clear-DnsClientCache }


# ── Clipboard ─────────────────────────────────────────────────

function cpy { Set-Clipboard $args[0] }
function pst { Get-Clipboard }


# ── Process Management ────────────────────────────────────────

function pkill($name) { Get-Process $name -ErrorAction SilentlyContinue | Stop-Process }
function pgrep($name) { Get-Process $name }
function k9 { Stop-Process -Name $args[0] }


# ── Shell Integrations ───────────────────────────────────────

# Atuin — enhanced shell history
if (Test-CommandExists atuin) {
    atuin init powershell | Out-String | Invoke-Expression
} else {
    try {
        winget install -e Atuinsh.Atuin
        Invoke-Expression (& { (atuin init powershell | Out-String) })
    } catch {
        Write-Error "Failed to install atuin. Error: $_"
    }
}

# Zoxide — smart cd with frecency
if (Test-CommandExists zoxide) {
    Invoke-Expression (& { (zoxide init powershell | Out-String) })
} else {
    try {
        winget install -e --id ajeetdsouza.zoxide
        Invoke-Expression (& { (zoxide init powershell | Out-String) })
    } catch {
        Write-Error "Failed to install zoxide. Error: $_"
    }
}

# Mise — polyglot runtime manager
$env:MISE_PWSH_CHPWD_WARNING = 0
if (Test-CommandExists mise) {
    (& mise activate pwsh) | Out-String | Invoke-Expression
}

# Kiro IDE shell integration
if ($env:TERM_PROGRAM -eq "kiro") {
    . "$(kiro --locate-shell-integration-path pwsh)"
}
