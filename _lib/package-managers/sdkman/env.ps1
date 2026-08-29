# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the sdkman component.
#>

$Version = (Get-Item Env:\SDKMAN_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\sdkman\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
