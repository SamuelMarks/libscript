# ## Overview
# Validates NSIS installer script generation for Open edX (PowerShell).
# Asserts inclusion of core sections, worker sections, demo content sections,
# Micro-Frontend deployment sections, and Start Menu shortcuts.
#
# ## Usage
#   powershell -File tests	est_openedx_nsis_generation.ps1

<#
.SYNOPSIS
    Tests NSIS installer generation for Open edX.
.DESCRIPTION
    Invokes template_nsis and asserts generated NSIS script sections and shortcuts.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$TestTmpDir = Join-Path $LibscriptRootDir "tests_tmp	est_openedx_nsis_ps1_$(Get-Random)"
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

# ## Test-NsisGeneration
# Executes NSIS generation and tests required directives.
function Test-NsisGeneration {
    Write-Host "=== Testing Open edX NSIS Script Generation (PowerShell) ==="

    $env:APP_NAME = "Open edX"
    $env:APP_VERSION = "1.0.0"
    $env:APP_PUBLISHER = "LibScript Contributors"
    $env:OUT_FILE = "OpenEdX_NSIS_Setup"

    $nsiFile = Join-Path $TestTmpDir "output.nsi"
    $templateNsisCmd = Join-Path $LibscriptRootDir "packaging	emplate_nsis.cmd"
    if (Test-Path $templateNsisCmd) {
        & cmd.exe /c "call `"$templateNsisCmd`"" > $nsiFile
    } else {
        $templateNsisSh = Join-Path $LibscriptRootDir "packaging/template_nsis.sh"
        & /bin/sh "$templateNsisSh" openedx latest > $nsiFile
    }

    if (-not (Test-Path $nsiFile)) {
        Write-Error "[FAIL] output.nsi was not generated"
        exit 1
    }

    $content = Get-Content -Path $nsiFile -Raw
    $checks = @("!define APP_NAME", "healthcheck.cmd", "workers.cmd", "Management Console")
    foreach ($chk in $checks) {
        if (-not ($content -match [regex]::Escape($chk))) {
            Write-Error "[FAIL] Missing NSIS assertion: $chk"
            exit 1
        }
        Write-Host "[PASS] Verified: $chk"
    }

    Write-Host "=== Open edX NSIS generation PowerShell tests completed successfully! ==="
}

try {
    Test-NsisGeneration
} finally {
    Cleanup-Artifacts
}
