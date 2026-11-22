# ## Overview
#
# ## Usage
# Execute via PowerShell.
# PowerShell uninstallation script for Bento Builder stack.

$ErrorActionPreference = "Stop"

$LibscriptRoot = Resolve-Path (Join-Path $PSScriptRoot "..\..\..")
& (Join-Path $LibscriptRoot "_lib\virtualization\qemu\uninstall.ps1")
& (Join-Path $LibscriptRoot "_lib\virtualization\virtualbox\uninstall.ps1")
& (Join-Path $LibscriptRoot "_lib\iac\packer\uninstall.ps1")
& (Join-Path $LibscriptRoot "_lib\iac\vagrant\uninstall.ps1")
