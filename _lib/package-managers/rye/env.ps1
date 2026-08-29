# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the rye component.
#>

$Version = (Get-Item Env:\RYE_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\rye\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
