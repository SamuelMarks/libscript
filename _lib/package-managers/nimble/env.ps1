<#
.SYNOPSIS
Environment variable initialization script for the nimble component.
#>

$Version = (Get-Item Env:\NIMBLE_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\nimble\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
