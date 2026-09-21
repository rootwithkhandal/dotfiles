[CmdletBinding(SupportsShouldProcess = $true)]
param(
    [string]$FontsPath,
    [switch]$Force
)

$ErrorActionPreference = 'Stop'

$scriptDirectory = if ($PSScriptRoot) {
    $PSScriptRoot
}
else {
    Split-Path -Parent $MyInvocation.MyCommand.Path
}

if (-not $FontsPath) {
    $FontsPath = Join-Path $scriptDirectory 'fonts'
}

$supportedExtensions = @('.fon', '.otf', '.ttc', '.ttf')
$fontsDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegistryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

function Get-FontRegistrySuffix {
    param([string]$Extension)

    switch ($Extension.ToLowerInvariant()) {
        '.fon' { ' (Font)' }
        '.otf' { ' (OpenType)' }
        '.ttc' { ' (TrueType Collection)' }
        default { ' (TrueType)' }
    }
}

if (-not (Test-Path -LiteralPath $FontsPath -PathType Container)) {
    throw "Fonts folder was not found: $FontsPath"
}

New-Item -ItemType Directory -Path $fontsDirectory -Force | Out-Null
New-Item -Path $fontRegistryPath -Force | Out-Null

$fontFiles = Get-ChildItem -LiteralPath $FontsPath -Recurse -File |
    Where-Object { $supportedExtensions -contains $_.Extension.ToLowerInvariant() }

if (-not $fontFiles) {
    Write-Warning "No supported font files were found in $FontsPath"
    return
}

$installed = 0
$wouldInstall = 0
$skipped = 0
$failed = 0

foreach ($font in $fontFiles) {
    $targetPath = Join-Path $fontsDirectory $font.Name
    $registryName = '{0}{1}' -f $font.BaseName, (Get-FontRegistrySuffix -Extension $font.Extension)

    if ((Test-Path -LiteralPath $targetPath) -and -not $Force) {
        Write-Host "Skipping existing font: $($font.Name)"
        $skipped++
        continue
    }

    try {
        if ($PSCmdlet.ShouldProcess($font.FullName, "Install font to $targetPath")) {
            Copy-Item -LiteralPath $font.FullName -Destination $targetPath -Force:$Force
            New-ItemProperty -Path $fontRegistryPath -Name $registryName -Value $font.Name -PropertyType String -Force | Out-Null
            Write-Host "Installed font: $($font.Name)"
            $installed++
        }
        elseif ($WhatIfPreference) {
            $wouldInstall++
        }
    }
    catch {
        Write-Warning "Failed to install $($font.FullName): $($_.Exception.Message)"
        $failed++
    }
}

Write-Host ''
Write-Host "Fonts processed: $($fontFiles.Count)"
Write-Host "Installed: $installed"
if ($WhatIfPreference) {
    Write-Host "Would install: $wouldInstall"
}
Write-Host "Skipped: $skipped"
Write-Host "Failed: $failed"

if ($failed -gt 0) {
    exit 1
}
