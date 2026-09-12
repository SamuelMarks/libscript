# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell uninstallation script for Packer.

$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget uninstall --silent --id=Hashicorp.Packer -e
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco uninstall -y packer
} else {
    Write-Output "Uninstall not supported automatically."
}
