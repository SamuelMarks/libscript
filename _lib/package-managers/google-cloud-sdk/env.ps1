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

$LibscriptHome = (Get-Item Env:\LIBSCRIPT_HOME -ErrorAction Ignore).Value
if (-not $LibscriptHome) { $LibscriptHome = Join-Path $env:USERPROFILE ".libscript" }

$BinPath = "$LibscriptHome\google-cloud-sdk\$Version\bin"
if ($env:PATH -notlike "*$BinPath*") {
    $env:PATH = "$BinPath;$env:PATH"
}

if (-not $env:CLOUDSDK_PYTHON) {
    if (Get-Command python3.12 -ErrorAction SilentlyContinue) {
        $env:CLOUDSDK_PYTHON = (Get-Command python3.12).Source
    } elseif (Get-Command python3.11 -ErrorAction SilentlyContinue) {
        $env:CLOUDSDK_PYTHON = (Get-Command python3.11).Source
    }
}
