# ## Overview
# Validates the 'pyenv' backend integration for Python virtual environments (PowerShell).
# 
# ## Usage
# powershell -File tests	est_python_pyenv_integration.ps1

<#
.SYNOPSIS
    Tests pyenv integration for Python virtual environments.
.DESCRIPTION
    Verifies that Python resolution and virtual environment creation work with pyenv backend.
#>

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$LibscriptRootDir = (Resolve-Path (Join-Path $ScriptDir "..")).Path

# ## Test-PyenvIntegration
# Validates pyenv resolution and virtualenv creation.
function Test-PyenvIntegration {
    $pyenvCmd = Get-Command pyenv -ErrorAction SilentlyContinue
    if (-not $pyenvCmd) {
        Write-Host "[WARN] pyenv is not installed. Skipping pyenv integration validation."
        exit 0
    }

    $env:LIBSCRIPT_PYTHON_BACKEND = "pyenv"
    $env:LIBSCRIPT_PYTHON_VENV_BACKEND = "venv"
    $testHome = Join-Path ([System.IO.Path]::GetTempPath()) "libscript_pyenv_ps1_$(Get-Random)"
    $env:LIBSCRIPT_HOME = $testHome

    Write-Host "[INFO] Testing pyenv integration..."

    $pyCmd = & pyenv which python 2>$null
    if (-not $pyCmd) {
        Write-Host "[WARN] No python version currently active in pyenv. Skipping."
        exit 0
    }

    $venvDir = Join-Path $testHome "test_venv"
    & $pyCmd -m venv $venvDir
    if (-not (Test-Path (Join-Path $venvDir "Scripts")) -and -not (Test-Path (Join-Path $venvDir "bin"))) {
        Write-Error "Failed to create venv using pyenv."
        exit 1
    }

    Write-Host "[INFO] Successfully created venv via pyenv at $venvDir."
    Remove-Item -Path $testHome -Recurse -Force -ErrorAction SilentlyContinue
    Write-Host "[INFO] pyenv integration validation complete."
}

Test-PyenvIntegration
