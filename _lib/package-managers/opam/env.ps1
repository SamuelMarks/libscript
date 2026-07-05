<#
.SYNOPSIS
Environment variable initialization script for the opam component.
#>

$Version = (Get-Item Env:\OPAM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\opam\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
