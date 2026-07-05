<#
.SYNOPSIS
Environment variable initialization script for the spack component.
#>

$Version = (Get-Item Env:\SPACK_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\spack\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
