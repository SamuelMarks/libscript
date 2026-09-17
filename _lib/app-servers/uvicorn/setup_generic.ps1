# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Generic PowerShell setup script for Uvicorn on Windows.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }

if ($Action -eq "install") {
    if (Get-Command "uvicorn" -ErrorAction SilentlyContinue) {
        Write-Host "uvicorn is already installed on the system."
        exit 0
    }
    if (Get-Command "uv" -ErrorAction SilentlyContinue) {
        Write-Host "Installing uvicorn via uv..."
        & uv tool install uvicorn
        exit 0
    }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) {
        Write-Host "Installing uvicorn via pip..."
        & pip install --user uvicorn
        exit 0
    }
    Write-Error "Python with pip or uv is required to install uvicorn."
    exit 1
} elseif ($Action -eq "uninstall") {
    if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall uvicorn }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y uvicorn }
    exit 0
} elseif ($Action -eq "test") {
    & uvicorn --version
    exit $LASTEXITCODE
}
