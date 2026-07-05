<#
.SYNOPSIS
Environment variable initialization script for the krew component.
#>

$Version = (Get-Item Env:\KREW_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\krew\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
