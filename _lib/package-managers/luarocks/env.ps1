<#
.SYNOPSIS
Environment variable initialization script for the luarocks component.
#>

$Version = (Get-Item Env:\LUAROCKS_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\luarocks\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
