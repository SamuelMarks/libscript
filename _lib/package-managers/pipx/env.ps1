# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the pipx component.
#>

$Version = (Get-Item Env:\PIPX_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pipx\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
