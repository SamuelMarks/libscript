<#
.SYNOPSIS
Environment variable initialization script for the openbao component.
#>

$Version = (Get-Item Env:\OPENBAO_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\openbao\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
