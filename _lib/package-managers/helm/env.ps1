# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the helm component.
#>

$Version = (Get-Item Env:\HELM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\helm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
