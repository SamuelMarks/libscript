# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the mise component.
#>

$Version = (Get-Item Env:\MISE_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\mise\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
