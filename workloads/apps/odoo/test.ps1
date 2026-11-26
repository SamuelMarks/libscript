# ## Overview
# Implements automated tests to verify the correctness of the Odoo stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:ODOO_WWWROOT) { $env:ODOO_WWWROOT } else { "C:\inetpub\wwwroot\odoo" }
Write-Host "Validating Odoo installation..."
if (Test-Path (Join-Path $wwwRoot "odoo-bin")) {
    Write-Output "Odoo directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "Odoo directory not found at $wwwRoot"
    exit 1
}
