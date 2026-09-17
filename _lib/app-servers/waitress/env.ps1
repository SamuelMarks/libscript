# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Waitress on Windows PowerShell.
#>
if (-not $env:WAITRESS_PORT) { $env:WAITRESS_PORT = "8000" }
if (-not $env:WAITRESS_HOST) { $env:WAITRESS_HOST = "0.0.0.0" }
if (-not $env:WAITRESS_THREADS) { $env:WAITRESS_THREADS = "4" }
