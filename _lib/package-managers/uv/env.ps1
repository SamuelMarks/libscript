# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the uv component.
#>

$Version = (Get-Item Env:\UV_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\uv\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
