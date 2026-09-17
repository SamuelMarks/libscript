# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Open edX on Windows PowerShell.
#>
if (-not $env:OPENEDX_VERSION) { $env:OPENEDX_VERSION = "master" }
if (-not $env:LMS_HOST) { $env:LMS_HOST = "openedx.local" }
if (-not $env:CMS_HOST) { $env:CMS_HOST = "studio.openedx.local" }
if (-not $env:LMS_PORT) { $env:LMS_PORT = "8000" }
if (-not $env:CMS_PORT) { $env:CMS_PORT = "8001" }
$LibHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $env:USERPROFILE ".libscript" }
if (-not $env:OPENEDX_INSTALL_DIR) { $env:OPENEDX_INSTALL_DIR = Join-Path $LibHome "openedx" }
