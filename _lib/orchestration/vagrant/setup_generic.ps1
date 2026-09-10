# ## Overview
# PowerShell setup_generic script for Vagrant on Windows.

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command vagrant -ErrorAction SilentlyContinue) {
        Write-Output "Vagrant is already installed."
        exit 0
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --silent --force --id=Hashicorp.Vagrant -e --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install -y vagrant
    } else {
        Write-Error "Neither winget nor choco found to install Vagrant."
        exit 1
    }
}
