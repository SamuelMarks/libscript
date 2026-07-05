<#
.SYNOPSIS
Environment variable initialization script for the sdkman component.
#>

$Version = (Get-Item Env:\SDKMAN_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\sdkman\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
