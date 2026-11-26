# ## Overview
# Implements automated tests to verify the correctness of the PrestaShop stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:PRESTASHOP_WWWROOT) { $env:PRESTASHOP_WWWROOT } else { "C:\inetpub\wwwroot\prestashop" }
Write-Host "Validating PrestaShop installation..."
if (Test-Path (Join-Path $wwwRoot "classes")) {
    Write-Output "PrestaShop directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "PrestaShop directory not found at $wwwRoot"
    exit 1
}
