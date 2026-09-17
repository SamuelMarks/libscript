# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Generic PowerShell setup script for uWSGI on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    if (Get-Command "uwsgi" -ErrorAction SilentlyContinue) {
        Write-Host "uwsgi is already installed on the system."
        exit 0
    }
    if (Get-Command "uv" -ErrorAction SilentlyContinue) {
        Write-Host "Installing uwsgi via uv..."
        & uv tool install uwsgi
        exit 0
    }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) {
        Write-Host "Installing uwsgi via pip..."
        & pip install --user uwsgi
        exit 0
    }
    Write-Error "Python with pip or uv is required to install uwsgi."
    exit 1
} elseif ($Action -eq "uninstall") {
    if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall uwsgi }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y uwsgi }
    exit 0
} elseif ($Action -eq "test") {
    & uwsgi --version
    exit $LASTEXITCODE
}
