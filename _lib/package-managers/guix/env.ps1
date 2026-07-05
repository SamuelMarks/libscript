<#
.SYNOPSIS
Environment variable initialization script for the guix component.
#>

$Version = (Get-Item Env:\GUIX_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\guix\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
