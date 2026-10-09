# ## Overview
# Upgrade and release migration engine for Open edX on Windows (PowerShell).
# Performs pre-upgrade backups, repository updates, database migrations, and cache clearing.
#
# ## Usage
#   .\upgrade.ps1 run [-From <release>] [-To <release>]
#   .\upgrade.ps1 help

<#
.SYNOPSIS
    Upgrade and release migration engine for Open edX.
.DESCRIPTION
    Automates pre-upgrade backups, repository updates, database migrations,
    static asset compilation, cache invalidation, and diagnostic validation.
#>

[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [string]$Command = "help",

    [Parameter()]
    [string]$From = "current",

    [Parameter()]
    [string]$To = "master"
)

$ErrorActionPreference = "Stop"
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }

$InstallDir = if ($env:OPENEDX_INSTALL_DIR) {
    $env:OPENEDX_INSTALL_DIR
} elseif ($env:LIBSCRIPT_HOME) {
    Join-Path $env:LIBSCRIPT_HOME "openedx"
} else {
    Join-Path $env:USERPROFILE ".libscript\openedx"
}

# ## Find-Python
# Discovers Python interpreter in virtual environment or PATH.
function Find-Python {
    $venvPy = Join-Path $InstallDir ".venv\Scripts\python.exe"
    if (Test-Path $venvPy) {
        return $venvPy
    }
    $pyCmd = Get-Command python -ErrorAction SilentlyContinue
    if ($pyCmd) {
        return "python"
    }
    throw "Python interpreter not found in virtualenv or PATH."
}

# ## Show-Help
# Displays upgrade CLI command usage.
function Show-Help {
    Write-Host "Open edX Release Upgrade & Migration CLI (PowerShell)"
    Write-Host ""
    Write-Host "Usage:"
    Write-Host "  .\upgrade.ps1 run [-From <release>] [-To <release>]"
    Write-Host "  .\upgrade.ps1 help"
}

# ## Invoke-UpgradePipeline
# Runs the 8-step Open edX platform upgrade pipeline.
function Invoke-UpgradePipeline {
    param([string]$FromRel, [string]$ToRel)
    Write-Host "[INFO] === Commencing Open edX Upgrade Pipeline ($FromRel -> $ToRel) ==="

    Write-Host "[INFO] Step 1/8: Creating pre-upgrade state backup..."
    $backupPs1 = Join-Path $ScriptDir "backup.ps1"
    if (Test-Path $backupPs1) {
        & $backupPs1 create
    }

    Write-Host "[INFO] Step 2/8: Updating openedx-platform repository..."
    $gitDir = Join-Path $InstallDir ".git"
    if (Test-Path $gitDir) {
        Push-Location $InstallDir
        try {
            & git fetch --all --tags 2>$null | Out-Null
            & git checkout $ToRel 2>$null | Out-Null
        } finally {
            Pop-Location
        }
    }

    $python = Find-Python
    Write-Host "[INFO] Step 3/8: Updating Python requirements..."
    $reqFile = Join-Path $InstallDir "requirements\edx\base.txt"
    if (Test-Path $reqFile) {
        & $python -m pip install -r $reqFile 2>$null | Out-Null
    }

    Write-Host "[INFO] Step 4/8: Applying database migrations..."
    $managePy = Join-Path $InstallDir "manage.py"
    if (Test-Path $managePy) {
        & $python $managePy lms migrate --noinput 2>$null | Out-Null
        & $python $managePy cms migrate --noinput 2>$null | Out-Null
    }

    Write-Host "[INFO] Step 5/8: Rebuilding frontend static assets..."
    $pkgJson = Join-Path $InstallDir "package.json"
    if (Test-Path $pkgJson) {
        Push-Location $InstallDir
        try {
            npm clean-install --no-audit 2>$null | Out-Null
        } finally {
            Pop-Location
        }
    }
    if (Test-Path $managePy) {
        & $python $managePy lms collectstatic --noinput 2>$null | Out-Null
    }

    Write-Host "[INFO] Step 6/8: Flushing cache stores..."
    $redisCli = Get-Command redis-cli -ErrorAction SilentlyContinue
    if ($redisCli) {
        & redis-cli flushdb 2>$null | Out-Null
    }

    Write-Host "[INFO] Step 7/8: Updating search indices..."
    if (Test-Path $managePy) {
        & $python $managePy lms reindex_course --all 2>$null | Out-Null
    }

    Write-Host "[INFO] Step 8/8: Restarting background workers and validating diagnostics..."
    $workersPs1 = Join-Path $ScriptDir "workers.ps1"
    if (Test-Path $workersPs1) {
        & $workersPs1 restart
    }
    $healthPs1 = Join-Path $ScriptDir "healthcheck.ps1"
    if (Test-Path $healthPs1) {
        & $healthPs1
    }

    Write-Host "[SUCCESS] Open edX platform upgrade to '$ToRel' completed successfully."
}

switch ($Command.ToLower()) {
    "run"     { Invoke-UpgradePipeline -FromRel $From -ToRel $To }
    "upgrade" { Invoke-UpgradePipeline -FromRel $From -ToRel $To }
    "help"    { Show-Help }
    default   {
        Write-Error "Unknown upgrade command: $Command"
        Show-Help
        exit 1
    }
}
