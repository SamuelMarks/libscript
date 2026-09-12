# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell uninstallation script for Vagrant.

$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget uninstall --silent --id=Hashicorp.Vagrant -e
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco uninstall -y vagrant
} else {
    Write-Output "Uninstall not supported automatically."
}
