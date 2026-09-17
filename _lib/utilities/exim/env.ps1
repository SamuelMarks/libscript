# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Environment script for Exim on Windows PowerShell.
#>
if (-not $env:EXIM_SMTP_PORT) { $env:EXIM_SMTP_PORT = "25" }
if (-not $env:EXIM_RELAY_FROM_HOSTS) { $env:EXIM_RELAY_FROM_HOSTS = "127.0.0.1" }
