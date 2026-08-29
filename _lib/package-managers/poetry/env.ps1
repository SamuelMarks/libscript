# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the poetry component.
#>

$Version = (Get-Item Env:\POETRY_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\poetry\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
