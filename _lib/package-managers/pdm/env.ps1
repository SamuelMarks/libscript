# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the pdm component.
#>

$Version = (Get-Item Env:\PDM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pdm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
