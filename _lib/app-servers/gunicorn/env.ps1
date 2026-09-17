# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Gunicorn on Windows PowerShell.
#>
if (-not $env:GUNICORN_WORKERS) { $env:GUNICORN_WORKERS = "2" }
if (-not $env:GUNICORN_BIND) { $env:GUNICORN_BIND = "0.0.0.0:8000" }
$GunVer = if ($env:GUNICORN_VERSION) { $env:GUNICORN_VERSION } else { "latest" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

$GunBin = Join-Path $LibHome "gunicorn\$GunVer\Scripts"
if (Test-Path $GunBin) {
    $env:PATH = "$GunBin;$env:PATH"
}
