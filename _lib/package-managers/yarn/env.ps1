<#
.SYNOPSIS
Environment variable initialization script for the yarn component.
#>

$Version = (Get-Item Env:\YARN_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\yarn\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
