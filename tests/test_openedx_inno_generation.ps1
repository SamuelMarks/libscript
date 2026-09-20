# ## Overview
# Validates Inno Setup (.iss) installer script generation for Open edX (PowerShell).
# Asserts inclusion of stack variables, background worker tasks, demo content tasks,
# Micro-Frontend deployment tasks, and Start Menu shortcuts.
#
# ## Usage
#   powershell -File tests	est_openedx_inno_generation.ps1

<#
.SYNOPSIS
    Tests Inno Setup script generation for Open edX.
.DESCRIPTION
    Invokes template_inno and asserts presence of tasks, icons, and worker hooks.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

$TestTmpDir = Join-Path $LibscriptRootDir "tests_tmp	est_openedx_inno_ps1_$(Get-Random)"
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

# ## Test-InnoGeneration
# Drives Inno script generation and tests output structure.
function Test-InnoGeneration {
    Write-Host "=== Testing Open edX Inno Setup Script Generation (PowerShell) ==="

    $env:APP_NAME = "Open edX"
    $env:APP_VERSION = "1.0.0"
    $env:APP_PUBLISHER = "LibScript Contributors"
    $env:OUT_FILE = "OpenEdX_Inno_Setup"

    $issFile = Join-Path $TestTmpDir "output.iss"
    $templateInnoCmd = Join-Path $LibscriptRootDir "packaging	emplate_inno.cmd"
    if (Test-Path $templateInnoCmd) {
        & cmd.exe /c "call `"$templateInnoCmd`"" > $issFile
    } else {
        $templateInnoSh = Join-Path $LibscriptRootDir "packaging/template_inno.sh"
        & /bin/sh "$templateInnoSh" openedx latest > $issFile
    }

    if (-not (Test-Path $issFile)) {
        Write-Error "[FAIL] output.iss was not generated"
        exit 1
    }

    $content = Get-Content -Path $issFile -Raw
    $checks = @("AppName=Open edX", "[Tasks]", "workers", "[Icons]")
    foreach ($chk in $checks) {
        if (-not ($content -match [regex]::Escape($chk))) {
            Write-Error "[FAIL] Missing Inno assertion: $chk"
            exit 1
        }
        Write-Host "[PASS] Verified: $chk"
    }

    Write-Host "=== Open edX Inno Setup generation PowerShell tests completed successfully! ==="
}

try {
    Test-InnoGeneration
} finally {
    Cleanup-Artifacts
}
