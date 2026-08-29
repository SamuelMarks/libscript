# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the go-pm component.
#>

$Version = (Get-Item Env:\GO_PM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\go-pm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
