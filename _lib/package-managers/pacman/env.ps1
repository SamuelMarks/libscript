<#
.SYNOPSIS
Environment variable initialization script for the pacman component.
#>

$Version = (Get-Item Env:\PACMAN_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pacman\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
