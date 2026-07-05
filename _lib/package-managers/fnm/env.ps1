<#
.SYNOPSIS
Environment variable initialization script for the fnm component.
#>

$Version = (Get-Item Env:\FNM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\fnm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
