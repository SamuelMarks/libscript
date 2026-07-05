<#
.SYNOPSIS
Environment variable initialization script for the rbenv component.
#>

$Version = (Get-Item Env:\RBENV_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\rbenv\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
