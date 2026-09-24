# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the WooCommerce e-commerce platform stack.

.DESCRIPTION
Execute this script to install and configure woocommerce on the local system.
#>

$ErrorActionPreference = "Stop"

$WwwRoot = if ($env:WOOCOMMERCE_WWWROOT) { $env:WOOCOMMERCE_WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
$WooVersion = if ($env:WOOCOMMERCE_VERSION) { $env:WOOCOMMERCE_VERSION } else { "latest" }

$pluginDir = Join-Path $WwwRoot "wp-content\plugins\woocommerce"

if (Test-Path $pluginDir) {
    Write-Host "[OK] WooCommerce already installed at $pluginDir."
    exit 0
}

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$libDir = Resolve-Path (Join-Path $scriptDir "..\..\..")
$wpSetup = Join-Path $libDir "stacks\cms\wordpress\setup.ps1"

Write-Host "Running WordPress Setup for WooCommerce..."
if (Test-Path $wpSetup) {
    & $wpSetup
}

if (-not (Test-Path $pluginDir)) {
    Write-Host "Downloading WooCommerce ($WooVersion)..."
    $dlUrl = if ($WooVersion -eq "latest") {
        "https://downloads.wordpress.org/plugin/woocommerce.zip"
    } else {
        "https://downloads.wordpress.org/plugin/woocommerce.$WooVersion.zip"
    }

    $tmpZip = Join-Path $env:TEMP "woocommerce_$(Get-Random).zip"
    if (Get-Command curl.exe -ErrorAction SilentlyContinue) {
        curl.exe -sSL "$dlUrl" -o "$tmpZip"
    } else {
        Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip -UseBasicParsing
    }
    
    $pluginDest = Join-Path $WwwRoot "wp-content\plugins"
    if (-not (Test-Path $pluginDest)) {
        New-Item -ItemType Directory -Force -Path $pluginDest | Out-Null
    }
    Expand-Archive -Path $tmpZip -DestinationPath $pluginDest -Force
    Remove-Item -Path $tmpZip -Force -ErrorAction SilentlyContinue
}

Write-Host "WooCommerce setup complete"
exit 0
