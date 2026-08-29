# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the minio component.
#>

$Version = (Get-Item Env:\MINIO_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\minio\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
