# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Generic PowerShell setup script for Waitress on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    if (Get-Command "waitress-serve" -ErrorAction SilentlyContinue) {
        Write-Host "waitress is already installed on the system."
        exit 0
    }
    if (Get-Command "uv" -ErrorAction SilentlyContinue) {
        Write-Host "Installing waitress via uv..."
        & uv tool install waitress
        exit 0
    }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) {
        Write-Host "Installing waitress via pip..."
        & pip install --user waitress
        exit 0
    }
    Write-Error "Python with pip or uv is required to install waitress."
    exit 1
} elseif ($Action -eq "uninstall") {
    if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall waitress }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y waitress }
    exit 0
} elseif ($Action -eq "test") {
    & waitress-serve --help
    exit $LASTEXITCODE
}
