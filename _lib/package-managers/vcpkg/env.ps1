# ## Overview
# PowerShell script for env.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Environment variable initialization script for the vcpkg component.
#>

$Version = (Get-Item Env:\VCPKG_VERSION -ErrorAction Ignore).Value
if (-not $Version) { $Version = "latest" }

$BinPath = "$env:LIBSCRIPT_HOME\vcpkg\$Version\bin"
$env:PATH = "$BinPath;$env:PATH"
