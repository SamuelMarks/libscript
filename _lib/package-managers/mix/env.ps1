<#
.SYNOPSIS
Environment variable initialization script for the mix component.
#>

$Version = (Get-Item Env:\MIX_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\mix\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
