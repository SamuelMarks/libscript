# ## Overview
# Validates the 'uv' backend integration for Python virtual environments (PowerShell).
# 
# ## Usage
# powershell -File tests	est_python_uv_integration.ps1

<#
.SYNOPSIS
    Tests uv integration for Python virtual environments.
.DESCRIPTION
    Verifies that Python resolution and environment setup work with uv backend.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

# ## Test-UvIntegration
# Validates uv tool availability, resolution, and environment creation.
function Test-UvIntegration {
    $uvCmd = Get-Command uv -ErrorAction SilentlyContinue
    if (-not $uvCmd) {
        Write-Host "[WARN] uv is not installed. Skipping uv integration validation."
        exit 0
    }

    $env:LIBSCRIPT_PYTHON_BACKEND = "uv"
    $env:LIBSCRIPT_PYTHON_VENV_BACKEND = "uv"
    $testHome = Join-Path ([System.IO.Path]::GetTempPath()) "libscript_uv_ps1_$(Get-Random)"
    $env:LIBSCRIPT_HOME = $testHome
    $env:DOWNLOAD_DIR = Join-Path $testHome "downloads"

    Write-Host "[INFO] Testing uv integration..."

    $pyPath = & uv python find 2>$null
    if (-not $pyPath) {
        Write-Host "[WARN] No python installed via uv. Skipping execution."
        exit 0
    }
    Write-Host "[INFO] Resolved python: $pyPath"

    $venvDir = Join-Path $testHome "test_venv"
    & uv venv $venvDir | Out-Null
    if (-not (Test-Path $venvDir)) {
        Write-Error "[ERROR] venv creation via uv failed."
        exit 1
    }

    Write-Host "[INFO] Successfully created venv via uv."
    Remove-Item -Path $testHome -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[INFO] uv integration validation complete."
}

Test-UvIntegration
