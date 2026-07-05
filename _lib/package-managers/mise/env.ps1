<#
.SYNOPSIS
Environment variable initialization script for the mise component.
#>

$Version = (Get-Item Env:\MISE_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\mise\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
