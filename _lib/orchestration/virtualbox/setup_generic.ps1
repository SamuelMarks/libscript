# ## Overview
# PowerShell setup_generic script for VirtualBox on Windows.

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {
        Write-Output "VirtualBox is already installed."
    } else {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
            winget install --silent --force --id=Oracle.VirtualBox -e --accept-package-agreements --accept-source-agreements
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
            choco install -y virtualbox
        } else {
            Write-Error "Neither winget nor choco found to install VirtualBox."
            exit 1
        }
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
        winget install --silent --force --id=Oracle.VirtualBoxExtensionPack -e --accept-package-agreements --accept-source-agreements 2>$null
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
        choco install -y virtualbox-extensionpack 2>$null
    }
}
