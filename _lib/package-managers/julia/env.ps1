<#
.SYNOPSIS
Environment variable initialization script for the julia component.
#>

$Version = (Get-Item Env:\JULIA_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\julia\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
