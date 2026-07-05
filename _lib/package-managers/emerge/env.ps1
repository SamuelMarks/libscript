<#
.SYNOPSIS
Environment variable initialization script for the emerge component.
#>

$Version = $env:EMERGE_VERSION
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\emerge\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
