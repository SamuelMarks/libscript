# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
    Generic setup logic for nodeenv on Windows PowerShell.
.DESCRIPTION
    Handles installation and uninstallation of nodeenv via uv, pipx, or pip.
#>
$Action = if ($env:ACTION) { $env:ACTION } else { "install" }
$Version = if ($env:NODEENV_VERSION) { $env:NODEENV_VERSION } else { "latest" }

if ($Action -eq "install") {
    if (Get-Command "nodeenv" -ErrorAction SilentlyContinue) {
        Write-Host "nodeenv is already installed on the system."
        exit 0
    }
    if (Get-Command "uv" -ErrorAction SilentlyContinue) {
        Write-Host "Installing nodeenv via uv..."
        & uv tool install nodeenv
        exit 0
    }
    if (Get-Command "pipx" -ErrorAction SilentlyContinue) {
        Write-Host "Installing nodeenv via pipx..."
        & pipx install nodeenv
        exit 0
    }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) {
        Write-Host "Installing nodeenv via pip..."
        & pip install --user nodeenv
        exit 0
    }
    Write-Error "Python with uv, pipx, or pip is required to install nodeenv."
    exit 1
} elseif ($Action -eq "uninstall") {
    if (Get-Command "uv" -ErrorAction SilentlyContinue) { & uv tool uninstall nodeenv }
    if (Get-Command "pipx" -ErrorAction SilentlyContinue) { & pipx uninstall nodeenv }
    if (Get-Command "pip" -ErrorAction SilentlyContinue) { & pip uninstall -y nodeenv }
    exit 0
} elseif ($Action -eq "test") {
    & nodeenv --version
    exit $LASTEXITCODE
}
