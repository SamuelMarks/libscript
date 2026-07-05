<#
.SYNOPSIS
Environment variable initialization script for the mamba component.
#>

$Version = (Get-Item Env:\MAMBA_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\mamba\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
