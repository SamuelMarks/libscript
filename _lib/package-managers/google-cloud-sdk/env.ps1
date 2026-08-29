# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the google-cloud-sdk component.
#>

$Version = (Get-Item Env:\GOOGLE_CLOUD_SDK_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\google-cloud-sdk\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
