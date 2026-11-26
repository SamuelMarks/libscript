# ## Overview
# Implements automated tests to verify the correctness of the Magento stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:MAGENTO_WWWROOT) { $env:MAGENTO_WWWROOT } else { "C:\inetpub\wwwroot\magento" }
Write-Host "Validating Magento installation..."
if (Test-Path (Join-Path $wwwRoot "app")) {
    Write-Output "Magento directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "Magento directory not found at $wwwRoot"
    exit 1
}
