<#
.SYNOPSIS
Environment variable initialization script for the pdm component.
#>

$Version = (Get-Item Env:\PDM_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\pdm\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
