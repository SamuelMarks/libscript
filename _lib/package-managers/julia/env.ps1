# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the julia component.
#>

$Version = (Get-Item Env:\JULIA_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\julia\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
