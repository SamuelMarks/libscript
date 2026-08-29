# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the mas component.
#>

$Version = (Get-Item Env:\MAS_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\mas\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
