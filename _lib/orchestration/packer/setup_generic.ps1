# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell setup_generic script for Packer on Windows.

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command packer -ErrorAction SilentlyContinue) {
        Write-Output "Packer is already installed."
        exit 0
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --silent --force --id=Hashicorp.Packer -e --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install -y packer
    } else {
        Write-Error "Neither winget nor choco found to install Packer."
        exit 1
    }
}
