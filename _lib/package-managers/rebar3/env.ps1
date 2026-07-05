<#
.SYNOPSIS
Environment variable initialization script for the rebar3 component.
#>

$Version = (Get-Item Env:\REBAR3_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\rebar3\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
