<#
.SYNOPSIS
Environment variable initialization script for the scoop component.
#>

$Version = (Get-Item Env:\SCOOP_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\scoop\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
