# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the paru component.
#>

$Version = (Get-Item Env:\PARU_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\paru\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
