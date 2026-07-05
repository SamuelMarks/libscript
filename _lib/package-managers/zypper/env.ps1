<#
.SYNOPSIS
Environment variable initialization script for the zypper component.
#>

$Version = (Get-Item Env:\ZYPPER_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\zypper\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
