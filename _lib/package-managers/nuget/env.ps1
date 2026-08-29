# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the nuget component.
#>

$Version = (Get-Item Env:\NUGET_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\nuget\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
