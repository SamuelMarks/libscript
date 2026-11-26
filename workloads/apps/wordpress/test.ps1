# ## Overview
# Implements automated tests to verify the correctness of the WordPress stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:WORDPRESS_WWWROOT) { $env:WORDPRESS_WWWROOT } else { "C:\inetpub\wwwroot\wordpress" }
Write-Host "Validating WordPress installation..."
if (Test-Path (Join-Path $wwwRoot "wp-admin")) {
    Write-Output "WordPress directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "WordPress directory not found at $wwwRoot"
    exit 1
}
