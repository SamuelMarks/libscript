<#
.SYNOPSIS
Environment variable initialization script for the gcsfuse component.
#>

$Version = (Get-Item Env:\GCSFUSE_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\gcsfuse\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
