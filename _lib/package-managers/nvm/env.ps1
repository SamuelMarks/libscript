# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the nvm component.
#>

$Version = (Get-Item Env:\NVM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\nvm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
