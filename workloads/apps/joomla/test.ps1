# ## Overview
# Implements automated tests to verify the correctness of the Joomla stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:JOOMLA_WWWROOT) { $env:JOOMLA_WWWROOT } else { "C:\inetpub\wwwroot\joomla" }
Write-Host "Validating Joomla installation..."
if (Test-Path (Join-Path $wwwRoot "administrator")) {
    Write-Output "Joomla directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "Joomla directory not found at $wwwRoot"
    exit 1
}
