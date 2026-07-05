<#
.SYNOPSIS
Environment variable initialization script for the rustup component.
#>

$Version = (Get-Item Env:\RUSTUP_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\rustup\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
