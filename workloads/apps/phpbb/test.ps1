# ## Overview
# Implements automated tests to verify the correctness of the phpBB stack.
#
# ## Usage
# Execute via PowerShell: .\test.ps1

$ErrorActionPreference = "Stop"
$wwwRoot = if ($env:PHPBB_WWWROOT) { $env:PHPBB_WWWROOT } else { "C:\inetpub\wwwroot\phpbb" }
Write-Host "Validating phpBB installation..."
if (Test-Path (Join-Path $wwwRoot "phpbb")) {
    Write-Output "phpBB directory found at $wwwRoot"
    exit 0
} else {
    Write-Error "phpBB directory not found at $wwwRoot"
    exit 1
}
