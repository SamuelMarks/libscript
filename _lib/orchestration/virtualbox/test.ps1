# ## Overview
# PowerShell test script for VirtualBox.
[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {
    & VBoxManage --version
    & VBoxManage list extpacks
} else {
    Write-Error "VBoxManage not found in PATH."
    exit 1
}
