# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell uninstallation script for QEMU.

$ErrorActionPreference = "Stop"

if (Get-Command winget -ErrorAction SilentlyContinue) {
    winget uninstall --silent --id=SoftwareFreedomConservancy.QEMU -e
} elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    choco uninstall -y qemu
} else {
    Write-Output "Uninstall not supported automatically."
}
