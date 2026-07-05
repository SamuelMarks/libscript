<#
.SYNOPSIS
Environment variable initialization script for the yay component.
#>

$Version = (Get-Item Env:\YAY_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\yay\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
