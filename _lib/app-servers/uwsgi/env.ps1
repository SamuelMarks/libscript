# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for uWSGI on Windows PowerShell.
#>
if (-not $env:UWSGI_WORKERS) { $env:UWSGI_WORKERS = "2" }
$UwsgiVer = if ($env:UWSGI_VERSION) { $env:UWSGI_VERSION } else { "2.0.24" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }

$UwsgiBin = Join-Path $LibHome "uwsgi\$UwsgiVer\bin"
if (Test-Path $UwsgiBin) {
    $env:PATH = "$UwsgiBin;$env:PATH"
}
