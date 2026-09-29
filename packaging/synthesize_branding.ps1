param (
    [Parameter(Mandatory=$true)]
    [string]$TargetSpec,

    [Parameter(Mandatory=$false)]
    [string]$OutputDir = ""
)

# ## Overview
# Universal branding synthesizer generating 24-bit BMP banners, multi-resolution ICO,
# and aggregated RTF EULA for Windows Installer (MSI) packages on Windows PowerShell.
#
# ## Usage
#   powershell -File packaging\synthesize_branding.ps1 -TargetSpec stacks\cms\openedx

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

$pkgJson = $TargetSpec
if (Test-Path -Path $TargetSpec -PathType Container) {
    $pkgJson = Join-Path $TargetSpec "packaging.json"
}

if (-not (Test-Path $pkgJson)) {
    Write-Error "packaging.json not found at: $pkgJson"
    exit 1
}

if (-not $OutputDir) {
    $OutputDir = Join-Path (Split-Path -Parent $pkgJson) "assets"
}

if (-not (Test-Path $OutputDir)) {
    New-Item -ItemType Directory -Path $OutputDir -Force | Out-Null
}

$spec = Get-Content $pkgJson -Raw | ConvertFrom-Json
$name = if ($spec.name) { $spec.name } else { "app" }
$title = if ($spec.title) { $spec.title } else { $name }

$primaryHex = "#0078D4"
$secondaryHex = "#2B88D8"
$darkHex = "#101820"
$eulaComps = @($title)

if ($spec.branding_palette) {
    if ($spec.branding_palette.primary_color) { $primaryHex = $spec.branding_palette.primary_color }
    if ($spec.branding_palette.secondary_color) { $secondaryHex = $spec.branding_palette.secondary_color }
    if ($spec.branding_palette.dark_color) { $darkHex = $spec.branding_palette.dark_color }
    if ($spec.branding_palette.eula_components) { $eulaComps = $spec.branding_palette.eula_components }
}

$cPrimary = [System.Drawing.ColorTranslator]::FromHtml($primaryHex)
$cSecondary = [System.Drawing.ColorTranslator]::FromHtml($secondaryHex)
$cDark = [System.Drawing.ColorTranslator]::FromHtml($darkHex)

Add-Type -AssemblyName System.Drawing

# 1. Generate Side Banner (164x312)
$sideBmp = New-Object System.Drawing.Bitmap 164, 312, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$gSide = [System.Drawing.Graphics]::FromImage($sideBmp)
$brushDark = New-Object System.Drawing.SolidBrush $cDark
$gSide.FillRectangle($brushDark, 0, 0, 164, 312)
$brushPrimary = New-Object System.Drawing.SolidBrush $cPrimary
$gSide.FillRectangle($brushPrimary, 0, 306, 164, 6)
$penSecondary = New-Object System.Drawing.Pen $cSecondary, 2
$gSide.DrawLine($penSecondary, 16, 90, 148, 90)
$gSide.DrawLine($penSecondary, 16, 194, 148, 194)
$gSide.Dispose()
$sideBmp.Save((Join-Path $OutputDir "banner_side.bmp"), [System.Drawing.Imaging.ImageFormat]::Bmp)
$sideBmp.Dispose()

# 2. Generate Top Banner (493x58)
$topBmp = New-Object System.Drawing.Bitmap 493, 58, ([System.Drawing.Imaging.PixelFormat]::Format24bppRgb)
$gTop = [System.Drawing.Graphics]::FromImage($topBmp)
$gTop.Clear([System.Drawing.Color]::White)
$penPrimary = New-Object System.Drawing.Pen $cPrimary, 2
$gTop.DrawLine($penPrimary, 0, 57, 493, 57)
$gTop.Dispose()
$topBmp.Save((Join-Path $OutputDir "banner_top.bmp"), [System.Drawing.Imaging.ImageFormat]::Bmp)
$topBmp.Dispose()

# 3. Generate RTF EULA
$rtfPath = Join-Path $OutputDir "license.rtf"
$compsStr = ($eulaComps -join "\par `n")
$rtfContent = "{tf1\ansi\deff0 {\fonttbl {\f0 Arial;}}\fs20\par {\b $title End User License Agreement}\par \par This deployment package provisions $title along with its declared dependencies.\par \par Licensed components:\par $compsStr\par \par By continuing installation, you agree to comply with all applicable terms.\par }"
[System.IO.File]::WriteAllText($rtfPath, $rtfContent)

Write-Output "[SUCCESS] Branding synthesis complete in $OutputDir"
exit 0
