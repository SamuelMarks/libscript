<#
.SYNOPSIS
Environment variable initialization script for the rvm component.
#>

$Version = (Get-Item Env:\RVM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\rvm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
