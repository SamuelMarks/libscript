# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    PowerShell generic setup script for MySQL on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    if (Get-Command "mysql" -ErrorAction SilentlyContinue) {
        Write-Host "MySQL is already installed on the system."
        exit 0
    }
    if (Get-Command "winget" -ErrorAction SilentlyContinue) {
        Write-Host "Installing MySQL via winget..."
        & winget install --id Oracle.MySQL -e --silent --accept-package-agreements --accept-source-agreements
        exit 0
    }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) {
        Write-Host "Installing MySQL via chocolatey..."
        & choco install mysql -y
        exit 0
    }
    Write-Error "winget or choco is required to install MySQL on Windows."
    exit 1
} elseif ($Action -eq "uninstall") {
    if (Get-Command "winget" -ErrorAction SilentlyContinue) { & winget uninstall --id Oracle.MySQL --silent }
    if (Get-Command "choco" -ErrorAction SilentlyContinue) { & choco uninstall mysql -y }
    exit 0
} elseif ($Action -eq "test") {
    & mysql --version
    exit $LASTEXITCODE
}
