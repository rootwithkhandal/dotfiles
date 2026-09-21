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

if (-not (Test-Path -LiteralPath $FontsPath -PathType Container)) {
    throw "Fonts folder was not found: $FontsPath"
}

$fontsDirectory = Join-Path $env:LOCALAPPDATA 'Microsoft\Windows\Fonts'
$fontRegistryPath = 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts'

# Map extensions to registry suffixes — used for the display name stored in the registry.
$registrySuffix = @{
    '.fon' = ' (Font)'
    '.otf' = ' (OpenType)'
    '.ttc' = ' (TrueType Collection)'
    '.ttf' = ' (TrueType)'
}

# Ensure target directory and registry key exist without clobbering existing data.
if (-not (Test-Path -LiteralPath $fontsDirectory)) {
    New-Item -ItemType Directory -Path $fontsDirectory -Force | Out-Null
}
if (-not (Test-Path -LiteralPath $fontRegistryPath)) {
    New-Item -Path $fontRegistryPath -Force | Out-Null
}

# Build a set of already-registered font names for O(1) lookups.
$registeredFonts = @{}
if (Test-Path -LiteralPath $fontRegistryPath) {
    $regKey = Get-Item -LiteralPath $fontRegistryPath
    foreach ($name in $regKey.GetValueNames()) {
        $registeredFonts[$name] = $regKey.GetValue($name)
    }
}

# Collect font files using -Include (pushed down to the provider, avoids per-item Where-Object).
$fontFiles = @(Get-ChildItem -LiteralPath $FontsPath -Recurse -File -Include '*.fon', '*.otf', '*.ttc', '*.ttf')

if ($fontFiles.Count -eq 0) {
    Write-Warning "No supported font files were found in $FontsPath"
    return
}

$installed = 0
$wouldInstall = 0
$skipped = 0
$failed = 0

foreach ($font in $fontFiles) {
    $targetPath = Join-Path $fontsDirectory $font.Name
    $suffix = $registrySuffix[$font.Extension.ToLowerInvariant()]
    if (-not $suffix) { $suffix = ' (TrueType)' }
    $registryName = '{0}{1}' -f $font.BaseName, $suffix

    # Skip if both the file and the correct registry entry already exist.
    $fileExists = Test-Path -LiteralPath $targetPath
    $regCorrect = $registeredFonts.ContainsKey($registryName) -and
                  $registeredFonts[$registryName] -eq $targetPath

    if ($fileExists -and $regCorrect -and -not $Force) {
        Write-Verbose "Skipping already-installed font: $($font.Name)"
        $skipped++
        continue
    }

    try {
        if ($PSCmdlet.ShouldProcess($font.FullName, "Install font to $targetPath")) {
            Copy-Item -LiteralPath $font.FullName -Destination $targetPath -Force
            # Per-user fonts require the full path as the registry value.
            Set-ItemProperty -Path $fontRegistryPath -Name $registryName -Value $targetPath -Type String
            $registeredFonts[$registryName] = $targetPath
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

$summary = @"

Fonts processed: $($fontFiles.Count)
Installed:       $installed
Skipped:         $skipped
Failed:          $failed
"@

if ($WhatIfPreference) {
    $summary += "`nWould install:   $wouldInstall"
}

Write-Host $summary

if ($failed -gt 0) {
    exit 1
}
