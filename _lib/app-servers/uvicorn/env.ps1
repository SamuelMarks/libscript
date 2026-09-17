# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Uvicorn on Windows PowerShell.
#>
if (-not $env:UVICORN_PORT) { $env:UVICORN_PORT = "8000" }
if (-not $env:UVICORN_HOST) { $env:UVICORN_HOST = "0.0.0.0" }
if (-not $env:UVICORN_WORKERS) { $env:UVICORN_WORKERS = "2" }
