# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the xbps component.
#>

$Version = (Get-Item Env:\XBPS_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\xbps\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
