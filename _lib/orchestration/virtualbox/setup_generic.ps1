# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell setup_generic script for VirtualBox on Windows.

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command VBoxManage -ErrorAction SilentlyContinue) {
        Write-Output "VirtualBox is already installed."
    } else {
        if (Get-Command winget -ErrorAction SilentlyContinue) {
    libscript_depends @(\"Oracle.VirtualBox\")
        } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    libscript_depends @(\"virtualbox\")
        } else {
            Write-Error "Neither winget nor choco found to install VirtualBox."
            exit 1
        }
    }

    if (Get-Command winget -ErrorAction SilentlyContinue) {
    libscript_depends @(\"Oracle.VirtualBoxExtensionPack\")
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    libscript_depends @(\"virtualbox-extensionpack\")
    }
}
