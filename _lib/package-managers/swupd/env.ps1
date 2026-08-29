# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the swupd component.
#>

$Version = (Get-Item Env:\SWUPD_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\swupd\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
