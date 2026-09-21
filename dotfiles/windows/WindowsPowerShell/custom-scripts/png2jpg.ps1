<#
.SYNOPSIS
    Converts PNG files to JPG format.
.DESCRIPTION
    Converts a single PNG file or all PNG files in a folder to JPG.
    Usage:
        .\Convert-PngToJpg.ps1 -Path "C:\Images"                # convert all PNGs in folder
        .\Convert-PngToJpg.ps1 -Path "C:\Images\photo.png"      # convert a single file
        .\Convert-PngToJpg.ps1 -Path "C:\Images" -Quality 90    # set JPG quality (1-100)
        .\Convert-PngToJpg.ps1 -Path "C:\Images" -DeleteOriginal # delete PNG after conversion
#>

param(
    [Parameter(Mandatory = $true)]
    [string]$Path,

    [int]$Quality = 90,

    [switch]$DeleteOriginal
)

Add-Type -AssemblyName System.Drawing

function Convert-SinglePng {
    param([string]$PngPath, [int]$Quality)

    $PngPath = (Resolve-Path -LiteralPath $PngPath).Path
    $jpgPath = [System.IO.Path]::ChangeExtension($PngPath, "jpg")

    try {
        $bytes = [System.IO.File]::ReadAllBytes($PngPath)
        $ms = New-Object System.IO.MemoryStream(,$bytes)
        $image = [System.Drawing.Image]::FromStream($ms)

        $jpegCodec = [System.Drawing.Imaging.ImageCodecInfo]::GetImageEncoders() |
            Where-Object { $_.MimeType -eq "image/jpeg" }

        $encoderParams = New-Object System.Drawing.Imaging.EncoderParameters(1)
        $encoderParams.Param[0] = New-Object System.Drawing.Imaging.EncoderParameter(
            [System.Drawing.Imaging.Encoder]::Quality, $Quality
        )

        $image.Save($jpgPath, $jpegCodec, $encoderParams)
        $image.Dispose()
        $ms.Dispose()

        Write-Host "Converted: $PngPath -> $jpgPath" -ForegroundColor Green

        if ($DeleteOriginal) {
            Remove-Item $PngPath -Force
        }
    }
    catch {
        Write-Warning "Failed to convert '$PngPath': $_"
    }
}

if (Test-Path $Path -PathType Leaf) {
    # Single file
    if ($Path -match '\.png$') {
        Convert-SinglePng -PngPath $Path -Quality $Quality
    }
    else {
        Write-Error "The specified file is not a PNG."
    }
}
elseif (Test-Path $Path -PathType Container) {
    # Folder - process all PNGs
    $pngFiles = Get-ChildItem -Path $Path -Filter *.png -File
    if ($pngFiles.Count -eq 0) {
        Write-Host "No PNG files found in '$Path'."
    }
    foreach ($file in $pngFiles) {
        Convert-SinglePng -PngPath $file.FullName -Quality $Quality
    }
}
else {
    Write-Error "Path '$Path' not found."
}
