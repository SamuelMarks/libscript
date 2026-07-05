<#
.SYNOPSIS
Environment variable initialization script for the flatpak component.
#>

$Version = (Get-Item Env:\FLATPAK_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\flatpak\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
