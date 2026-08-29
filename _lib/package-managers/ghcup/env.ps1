# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the ghcup component.
#>

$Version = (Get-Item Env:\GHCUP_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\ghcup\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
