# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the hatch component.
#>

$Version = (Get-Item Env:\HATCH_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\hatch\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
