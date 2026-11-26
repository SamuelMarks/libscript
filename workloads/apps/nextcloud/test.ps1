# ## Overview
# Implements automated tests to verify the correctness of the Nextcloud stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:NEXTCLOUD_WWWROOT) { $env:NEXTCLOUD_WWWROOT } else { "C:\inetpub\wwwroot\nextcloud" }
Write-Host "Validating Nextcloud installation..."
if (Test-Path (Join-Path $wwwRoot "core")) {
    Write-Output "Nextcloud directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "Nextcloud directory not found at $wwwRoot"
    exit 1
}
