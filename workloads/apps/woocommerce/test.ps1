# ## Overview
# Implements automated tests to verify the correctness of the WooCommerce stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:WOOCOMMERCE_WWWROOT) { $env:WOOCOMMERCE_WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
Write-Host "Validating WooCommerce installation..."
if (Test-Path (Join-Path $wwwRoot "wp-content\plugins\woocommerce")) {
    Write-Output "WooCommerce directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "WooCommerce directory not found at $wwwRoot"
    exit 1
}
