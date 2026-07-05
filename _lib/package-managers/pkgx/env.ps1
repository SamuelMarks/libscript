<#
.SYNOPSIS
Environment variable initialization script for the pkgx component.
#>

$Version = (Get-Item Env:\PKGX_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pkgx\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
