# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell setup_generic script for Vagrant on Windows.

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command vagrant -ErrorAction SilentlyContinue) {
        Write-Output "Vagrant is already installed."
        exit 0
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
    libscript_depends @("Hashicorp.Vagrant")
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    libscript_depends @("vagrant")
    } else {
        Write-Error "Neither winget nor choco found to install Vagrant."
        exit 1
    }
}
