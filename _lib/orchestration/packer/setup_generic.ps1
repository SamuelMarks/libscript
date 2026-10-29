# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell setup_generic script for Packer on Windows.

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

if ($Action -eq "install") {
    if (Get-Command packer -ErrorAction SilentlyContinue) {
        Write-Output "Packer is already installed."
        exit 0
    }
    if (Get-Command winget -ErrorAction SilentlyContinue) {
    libscript_depends @("Hashicorp.Packer")
    } elseif (Get-Command choco -ErrorAction SilentlyContinue) {
    libscript_depends @("packer")
    } else {
        Write-Error "Neither winget nor choco found to install Packer."
        exit 1
    }
}
