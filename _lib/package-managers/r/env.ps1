<#
.SYNOPSIS
Environment variable initialization script for the r component.
#>

$Version = (Get-Item Env:\R_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\r\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
