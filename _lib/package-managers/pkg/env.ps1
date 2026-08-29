# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the pkg component.
#>

$Version = (Get-Item Env:\PKG_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pkg\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
