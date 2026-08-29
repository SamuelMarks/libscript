# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the macports component.
#>

$Version = (Get-Item Env:\MACPORTS_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\macports\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
