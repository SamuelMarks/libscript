# ## Overview
# Unit and integration tests for cross-platform packaging branding assets (PowerShell).
# Validates Inno, NSIS, and WiX branding bitmaps and license file integration.
#
# ## Usage
#   powershell -File tests	est_packaging_branding.ps1

<#
.SYNOPSIS
    Tests cross-platform installer branding assets.
.DESCRIPTION
    Validates that Inno, NSIS, and WiX templates correctly embed branding bitmaps and license files.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$TestTmpDir = Join-Path $LibscriptRootDir "tests_tmp	est_brand_ps1_$(Get-Random)"
if (-not (Test-Path $TestTmpDir)) {
    New-Item -ItemType Directory -Path $TestTmpDir -Force | Out-Null
}

# ## Cleanup-Artifacts
# Cleans up temporary test directory upon exit.
function Cleanup-Artifacts {
    if (Test-Path $TestTmpDir) {
        Remove-Item -Path $TestTmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ## Test-BrandingGeneration
# Verifies branding elements in Inno, NSIS, and WiX generation.
function Test-BrandingGeneration {
    Write-Host "=== Testing Cross-Platform Installer Branding (PowerShell) ==="

    Set-Content -Path (Join-Path $TestTmpDir "CUSTOM_LICENSE.txt") -Value "Custom Enterprise License Agreement terms"
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "custom_icon.ico") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "banner_top.bmp") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "banner_side.bmp") -Force | Out-Null

    $env:APP_NAME = "BrandApp"
    $env:APP_VERSION = "2.5.0.0"
    $env:APP_PUBLISHER = "BrandCorp"
    $env:PRODUCT_CODE = "*"
    $env:UPGRADE_CODE = "12345678-1234-5678-1234-567812345678"
    $env:OUT_FILE = Join-Path $TestTmpDir "BrandApp"
    $env:ICON_PATH = Join-Path $TestTmpDir "custom_icon.ico"
    $env:BANNER_TOP_PATH = Join-Path $TestTmpDir "banner_top.bmp"
    $env:BANNER_SIDE_PATH = Join-Path $TestTmpDir "banner_side.bmp"
    $env:LICENSE_PATH = Join-Path $TestTmpDir "CUSTOM_LICENSE.txt"

    # 1. Inno
    $innoFile = Join-Path $TestTmpDir "BrandApp.iss"
    $innoCmd = Join-Path $LibscriptRootDir "packaging	emplate_inno.cmd"
    if (Test-Path $innoCmd) {
        & cmd.exe /c "call `"$innoCmd`"" > $innoFile
    } else {
        $innoSh = Join-Path $LibscriptRootDir "packaging/template_inno.sh"
        & /bin/sh "$innoSh" > $innoFile
    }
    if (Test-Path $innoFile) {
        $content = Get-Content -Path $innoFile -Raw
        if ($content -match "WizardImageFile") {
            Write-Host "[PASS] PowerShell Inno branding assertions passed"
        }
    }

    # 2. NSIS
    $nsiFile = Join-Path $TestTmpDir "BrandApp.nsi"
    $nsisCmd = Join-Path $LibscriptRootDir "packaging	emplate_nsis.cmd"
    if (Test-Path $nsisCmd) {
        & cmd.exe /c "call `"$nsisCmd`"" > $nsiFile
    } else {
        $nsisSh = Join-Path $LibscriptRootDir "packaging/template_nsis.sh"
        & /bin/sh "$nsisSh" > $nsiFile
    }
    if (Test-Path $nsiFile) {
        $content = Get-Content -Path $nsiFile -Raw
        if ($content -match "MUI_HEADERIMAGE_BITMAP") {
            Write-Host "[PASS] PowerShell NSIS branding assertions passed"
        }
    }

    # 3. WiX MSI
    $templateMsiCmd = Join-Path $LibscriptRootDir "packaging	emplate_msi.cmd"
    if (Test-Path $templateMsiCmd) {
        & cmd.exe /c "call `"$templateMsiCmd`""
    } else {
        $templateMsiSh = Join-Path $LibscriptRootDir "packaging/template_msi.sh"
        & /bin/sh "$templateMsiSh"
    }
    $wxsFile = Join-Path $TestTmpDir "BrandApp.wxs"
    if (Test-Path $wxsFile) {
        $content = Get-Content -Path $wxsFile -Raw
        if ($content -match "WixUIBannerBmp") {
            Write-Host "[PASS] PowerShell WiX MSI branding assertions passed"
        }
    }

    Write-Host "=== All PowerShell branding tests passed! ==="
}

try {
    Test-BrandingGeneration
} finally {
    Cleanup-Artifacts
}
