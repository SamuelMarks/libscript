# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the sbt component.
#>

$Version = (Get-Item Env:\SBT_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\sbt\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
