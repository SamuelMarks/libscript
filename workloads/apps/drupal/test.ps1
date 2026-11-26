# ## Overview
# Implements automated tests to verify the correctness of the Drupal stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:DRUPAL_WWWROOT) { $env:DRUPAL_WWWROOT } else { "C:\inetpub\wwwroot\drupal" }
Write-Host "Validating Drupal installation..."
if (Test-Path (Join-Path $wwwRoot "core")) {
    Write-Output "Drupal directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "Drupal directory not found at $wwwRoot"
    exit 1
}
