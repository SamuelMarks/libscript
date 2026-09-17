# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Generic PowerShell setup script for Gunicorn on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    if (Get-Command "gunicorn" -ErrorAction SilentlyContinue) {
        Write-Host "gunicorn is already installed on the system."
        exit 0
    }
    if (Get-Command "uv" -ErrorAction SilentlyContinue) {
        Write-Host "Installing gunicorn via uv..."
        & uv tool install gunicorn
        exit 0
    }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) {
        Write-Host "Installing gunicorn via pip..."
        & pip install --user gunicorn
        exit 0
    }
    Write-Error "Python with pip or uv is required to install gunicorn."
    exit 1
} elseif ($Action -eq "uninstall") {
    if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall gunicorn }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y gunicorn }
    exit 0
} elseif ($Action -eq "test") {
    & gunicorn --version
    exit $LASTEXITCODE
}
