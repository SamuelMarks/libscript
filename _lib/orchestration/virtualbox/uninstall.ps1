# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell uninstallation script for VirtualBox.

$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget uninstall --silent --id=Oracle.VirtualBox -e
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco uninstall -y virtualbox
} else {
    Write-Output "Uninstall not supported automatically."
}
