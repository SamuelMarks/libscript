# ## Overview
# Unit and integration test for WiX MSI installer generation (PowerShell).
# Validates template generation and XML control structures.
#
# ## Usage
#   powershell -File tests	est_msi_generation.ps1

<#
.SYNOPSIS
    Integration tests for WiX MSI installer generation.
.DESCRIPTION
    Creates temporary assets, invokes template_msi, and validates XML structures.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$TestTmpDir = Join-Path $LibscriptRootDir "tests_tmp	est_msi_ps1_$(Get-Random)"
if (-not (Test-Path $TestTmpDir)) {
    New-Item -ItemType Directory -Path $TestTmpDir -Force | Out-Null
}

# ## Cleanup-Artifacts
# Removes temporary directory upon test completion.
function Cleanup-Artifacts {
    if (Test-Path $TestTmpDir) {
        Remove-Item -Path $TestTmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ## Test-MsiGeneration
# Drives test asset creation and asserts on generated WXS structure.
function Test-MsiGeneration {
    Write-Host "=== Testing WiX MSI Installer Generation (PowerShell) ==="

    Set-Content -Path (Join-Path $TestTmpDir "LICENSE.txt") -Value "LibScript Test License Agreement"
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "test_icon.ico") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "test_banner_top.bmp") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "test_banner_side.bmp") -Force | Out-Null

    $env:OUT_FILE = Join-Path $TestTmpDir "TestPackage"
    $env:APP_NAME = "TestStack"
    $env:APP_VERSION = "1.0.0.0"
    $env:APP_PUBLISHER = "LibScriptTest"
    $env:PRODUCT_CODE = "*"
    $env:UPGRADE_CODE = "12345678-1234-5678-1234-567812345678"
    $env:install_scope = "perMachine"
    $env:WELCOME_TEXT = "Welcome to TestStack"
    $env:ICON_PATH = Join-Path $TestTmpDir "test_icon.ico"
    $env:BANNER_TOP_PATH = Join-Path $TestTmpDir "test_banner_top.bmp"
    $env:BANNER_SIDE_PATH = Join-Path $TestTmpDir "test_banner_side.bmp"
    $env:LICENSE_PATH = Join-Path $TestTmpDir "LICENSE.txt"

    $templateMsiCmd = Join-Path $LibscriptRootDir "packaging	emplate_msi.cmd"
    if (Test-Path $templateMsiCmd) {
        & cmd.exe /c "call `"$templateMsiCmd`""
    } else {
        $templateMsiSh = Join-Path $LibscriptRootDir "packaging/template_msi.sh"
        & /bin/sh "$templateMsiSh"
    }

    $wxsFile = Join-Path $TestTmpDir "TestPackage.wxs"
    if (-not (Test-Path $wxsFile)) {
        Write-Error "[FAIL] Expected .wxs file was not generated"
        exit 1
    }
    Write-Host "[PASS] Generated $wxsFile"

    $content = Get-Content -Path $wxsFile -Raw
    $checks = @("WixUILicenseRtf", "WixUIBannerBmp", "WixUIDialogBmp", "Dlg_License")
    foreach ($chk in $checks) {
        if (-not ($content -match $chk)) {
            Write-Error "[FAIL] Missing assertion for $chk"
            exit 1
        }
    }

    Write-Host "[PASS] All PowerShell WiX assertions passed!"
}

try {
    Test-MsiGeneration
} finally {
    Cleanup-Artifacts
}
