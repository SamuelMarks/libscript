<#
.SYNOPSIS
Environment variable initialization script for the winget component.
#>

$Version = (Get-Item Env:\WINGET_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\winget\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
