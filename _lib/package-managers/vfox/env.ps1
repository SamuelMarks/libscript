<#
.SYNOPSIS
Environment variable initialization script for the vfox component.
#>

$Version = (Get-Item Env:\VFOX_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\vfox\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
