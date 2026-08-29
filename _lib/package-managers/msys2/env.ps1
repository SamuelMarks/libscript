# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the msys2 component.
#>

$Version = (Get-Item Env:\MSYS2_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\msys2\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
