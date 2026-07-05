<#
.SYNOPSIS
Environment variable initialization script for the snap component.
#>

$Version = (Get-Item Env:\SNAP_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\snap\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
