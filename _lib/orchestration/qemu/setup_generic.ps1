# ## Overview
# PowerShell script for setup_generic.ps1 for QEMU.
#
# ## Usage
# Execute via PowerShell.

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command qemu-system-x86_64 -ErrorAction SilentlyContinue) {
        Write-Output "QEMU is already installed."
        exit 0
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
    libscript_depends @("SoftwareFreedomConservancy.QEMU")
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    libscript_depends @("qemu")
    } else {
        Write-Error "Neither winget nor choco found to install QEMU."
        exit 1
    }
}
