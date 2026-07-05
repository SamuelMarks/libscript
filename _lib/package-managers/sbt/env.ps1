<#
.SYNOPSIS
Environment variable initialization script for the sbt component.
#>

$Version = (Get-Item Env:\SBT_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\sbt\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
