<#
.SYNOPSIS
Environment variable initialization script for the nix component.
#>

$Version = (Get-Item Env:\NIX_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\nix\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
