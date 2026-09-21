# ============================================================
#  Dotfiles Configuration Deployer
#  Symlinks/copies config files for WezTerm, Neovim, VS Code, etc.
# ============================================================

[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [switch]$Force,
    [switch]$SkipFonts
)

$ErrorActionPreference = 'Stop'

# ── Resolve repo root (parent of scripts/) ───────────────────

$scriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$repoRoot  = Split-Path -Parent $scriptDir

# ── Logging ──────────────────────────────────────────────────

$script:Log   = [System.Collections.Generic.List[string]]::new()
$script:Fails = 0

function Write-Step {
    param([string]$Message)
    Write-Host "`n:: $Message" -ForegroundColor Cyan
}

function Add-LogEntry {
    param(
        [ValidateSet('OK', 'FAIL', 'SKIP')]
        [string]$Status,
        [string]$Label,
        [string]$Detail
    )

    $prefix = switch ($Status) {
        'OK'   { '[OK]  ' }
        'FAIL' { '[FAIL]' }
        'SKIP' { '[SKIP]' }
    }

    $entry = "$prefix $Label"
    if ($Detail) { $entry += " - $Detail" }
    $script:Log.Add($entry)

    if ($Status -eq 'FAIL') { $script:Fails++ }
}

# ── Deploy helper ────────────────────────────────────────────

function Deploy-ConfigFile {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Source)) {
        Add-LogEntry -Status SKIP -Label $Label -Detail "source not found: $Source"
        return
    }

    $destDir = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $destDir)) {
        New-Item -ItemType Directory -Path $destDir -Force | Out-Null
    }

    try {
        if ($PSCmdlet.ShouldProcess($Source, "Deploy to $Destination")) {
            Copy-Item -LiteralPath $Source -Destination $Destination -Force
            Add-LogEntry -Status OK -Label $Label -Detail $Destination
        }
    }
    catch {
        Add-LogEntry -Status FAIL -Label $Label -Detail $_.Exception.Message
    }
}

function Deploy-ConfigDir {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Label
    )

    if (-not (Test-Path -LiteralPath $Source -PathType Container)) {
        Add-LogEntry -Status SKIP -Label $Label -Detail "source not found: $Source"
        return
    }

    try {
        if ($PSCmdlet.ShouldProcess($Source, "Deploy directory to $Destination")) {
            if (Test-Path -LiteralPath $Destination) {
                Remove-Item -LiteralPath $Destination -Recurse -Force
            }
            Copy-Item -LiteralPath $Source -Destination $Destination -Recurse -Force
            Add-LogEntry -Status OK -Label $Label -Detail $Destination
        }
    }
    catch {
        Add-LogEntry -Status FAIL -Label $Label -Detail $_.Exception.Message
    }
}

# ── 1. Fonts ─────────────────────────────────────────────────

if (-not $SkipFonts) {
    $fontInstaller = Join-Path $repoRoot 'fonts\install-fonts.ps1'

    if (Test-Path -LiteralPath $fontInstaller) {
        Write-Step 'Installing fonts'
        try {
            & $fontInstaller -Force:$Force
            Add-LogEntry -Status OK -Label 'Fonts'
        }
        catch {
            Add-LogEntry -Status FAIL -Label 'Fonts' -Detail $_.Exception.Message
        }
    }
    else {
        Add-LogEntry -Status SKIP -Label 'Fonts' -Detail "install-fonts.ps1 not found at $fontInstaller"
    }
}
else {
    Add-LogEntry -Status SKIP -Label 'Fonts' -Detail 'skipped via -SkipFonts'
}

# ── 2. WezTerm ───────────────────────────────────────────────

Write-Step 'Deploying WezTerm configuration'

Deploy-ConfigFile `
    -Source      (Join-Path $repoRoot 'terminals\wezterm\.wezterm.lua') `
    -Destination (Join-Path $HOME '.wezterm.lua') `
    -Label       'WezTerm config'

# ── 3. Neovim ────────────────────────────────────────────────

Write-Step 'Deploying Neovim configuration'

Deploy-ConfigDir `
    -Source      (Join-Path $repoRoot 'editors\nvim') `
    -Destination (Join-Path $env:LOCALAPPDATA 'nvim') `
    -Label       'Neovim config'

# ── 4. VS Code ───────────────────────────────────────────────

Write-Step 'Deploying VS Code configuration'

Deploy-ConfigFile `
    -Source      (Join-Path $repoRoot 'editors\vscode\settings.json') `
    -Destination (Join-Path $env:APPDATA 'Code\User\settings.json') `
    -Label       'VS Code settings'

# ── Summary ──────────────────────────────────────────────────

Write-Host ''
Write-Host '=============================================' -ForegroundColor White
Write-Host '  Deployment Summary' -ForegroundColor White
Write-Host '=============================================' -ForegroundColor White
$script:Log | ForEach-Object { Write-Host $_ }
Write-Host '---------------------------------------------'

if ($Fails -eq 0) {
    Write-Host 'All configurations deployed successfully!' -ForegroundColor Green
    Write-Host 'Note: Neovim will install plugins on its first launch.' -ForegroundColor Gray
}
else {
    Write-Host "Done with $Fails failure(s). Check the log above." -ForegroundColor Yellow
}

if ($Fails -gt 0) { exit 1 }
