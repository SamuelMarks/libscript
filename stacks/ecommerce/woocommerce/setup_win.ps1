$ErrorActionPreference = "Stop"

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$libDir = Resolve-Path (Join-Path $scriptDir "..\..\..")
$wpSetup = Join-Path $libDir "app\third_party\wordpress\setup_win.ps1"

Write-Host "Running WordPress Setup for WooCommerce..."
if (Test-Path $wpSetup) {
    & $wpSetup
} else {
    Write-Warning "WordPress setup script not found at $wpSetup"
    exit 1
}

$WwwRoot = if ($env:WWWROOT) { $env:WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
$WooVersion = if ($env:WOOCOMMERCE_VERSION) { $env:WOOCOMMERCE_VERSION } else { "latest" }

$pluginDir = Join-Path $WwwRoot "wp-content\plugins\woocommerce"

if (-not (Test-Path $pluginDir)) {
    Write-Host "Downloading WooCommerce ($WooVersion)..."
    $dlUrl = if ($WooVersion -eq "latest") {
        "https://downloads.wordpress.org/plugin/woocommerce.zip"
    } else {
        "https://downloads.wordpress.org/plugin/woocommerce.$WooVersion.zip"
    }

    $tmpZip = Join-Path $env:TEMP "woocommerce_$(Get-Random).zip"
    Invoke-WebRequest -Uri $dlUrl -OutFile $tmpZip
    
    $pluginDest = Join-Path $WwwRoot "wp-content\plugins"
    Expand-Archive -Path $tmpZip -DestinationPath $pluginDest -Force
    Remove-Item -Path $tmpZip -Force
}

Write-Host "WooCommerce setup complete"
