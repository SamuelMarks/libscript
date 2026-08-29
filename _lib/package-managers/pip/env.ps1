# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the pip component.
#>

$Version = (Get-Item Env:\PIP_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pip\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
