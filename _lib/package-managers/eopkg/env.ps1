<#
.SYNOPSIS
Environment variable initialization script for the eopkg component.
#>

$Version = (Get-Item Env:\EOPKG_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\eopkg\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
