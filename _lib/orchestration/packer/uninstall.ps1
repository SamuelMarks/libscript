# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell uninstallation script for Packer.

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")

libscript_uninstall_pkg -Packages @("Hashicorp.Packer", "packer")
