# ## Overview
# PowerShell script for setup_generic.ps1 for QEMU.
#
# ## Usage
# Execute via PowerShell.

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command qemu-system-x86_64 -ErrorAction SilentlyContinue) {
        Write-Output "QEMU is already installed."
        exit 0
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --silent --force --id=SoftwareFreedomConservancy.QEMU -e --accept-package-agreements --accept-source-agreements
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install -y qemu
    } else {
        Write-Error "Neither winget nor choco found to install QEMU."
        exit 1
    }
}
