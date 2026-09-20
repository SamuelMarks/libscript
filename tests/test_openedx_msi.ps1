# ## Overview
# Validates Open edX Windows Installer (.msi) packaging and WiX manifest generation (PowerShell).
# Checks Simple vs Advanced modes, browser launch automation, and parameter masking.
#
# ## Usage
#   powershell -File tests	est_openedx_msi.ps1

<#
.SYNOPSIS
    Tests Open edX MSI installer and WiX manifest generation.
.DESCRIPTION
    Validates WiX dialog definitions, properties, and custom actions generated for Open edX.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$TestTmpDir = Join-Path $LibscriptRootDir "tests_tmp	est_openedx_msi_ps1_$(Get-Random)"
if (-not (Test-Path $TestTmpDir)) {
    New-Item -ItemType Directory -Path $TestTmpDir -Force | Out-Null
}

# ## Cleanup-Artifacts
# Cleans up temporary test workspace.
function Cleanup-Artifacts {
    if (Test-Path $TestTmpDir) {
        Remove-Item -Path $TestTmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ## Test-OpenedxMsi
# Executes Open edX MSI build and asserts properties in generated WXS.
function Test-OpenedxMsi {
    Write-Host "=== Testing Open edX MSI Installer Generation (PowerShell) ==="

    Set-Content -Path (Join-Path $TestTmpDir "LICENSE.txt") -Value "Mock AGPLv3 Open edX License"
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "openedx.ico") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "banner_top.bmp") -Force | Out-Null
    New-Item -ItemType File -Path (Join-Path $TestTmpDir "banner_side.bmp") -Force | Out-Null

    $outBase = Join-Path $TestTmpDir "OpenEdX_Test_Setup"
    $buildCmd = Join-Path $LibscriptRootDir "packaging\build_openedx_msi.cmd"
    if (Test-Path $buildCmd) {
        & cmd.exe /c "call `"$buildCmd`" --out `"$outBase`" --version `"2.4.0.0`" --icon `"$TestTmpDir\openedx.ico`" --banner-top `"$TestTmpDir\banner_top.bmp`" --banner-side `"$TestTmpDir\banner_side.bmp`" --license `"$TestTmpDir\LICENSE.txt`""
    } else {
        $buildSh = Join-Path $LibscriptRootDir "packaging/build_openedx_msi.sh"
        & /bin/sh "$buildSh" --out "$outBase" --version "2.4.0.0" --icon "$TestTmpDir/openedx.ico" --banner-top "$TestTmpDir/banner_top.bmp" --banner-side "$TestTmpDir/banner_side.bmp" --license "$TestTmpDir/LICENSE.txt"
    }

    $wxsFile = "${outBase}.wxs"
    if (-not (Test-Path $wxsFile)) {
        Write-Error "[FAIL] Expected WXS manifest was not created: $wxsFile"
        exit 1
    }
    Write-Host "[PASS] Generated WiX manifest: $wxsFile"

    $content = Get-Content -Path $wxsFile -Raw
    $checks = @("SETUP_MODE", "LAUNCH_BROWSER", "Dlg_SetupType", "Dlg_Exit", "MsiHiddenProperties")
    foreach ($chk in $checks) {
        if (-not ($content -match $chk)) {
            Write-Error "[FAIL] Missing assertion: $chk"
            exit 1
        }
        Write-Host "[PASS] Verified: $chk"
    }

    Write-Host "=== Open edX MSI PowerShell tests completed successfully! ==="
}

try {
    Test-OpenedxMsi
} finally {
    Cleanup-Artifacts
}
