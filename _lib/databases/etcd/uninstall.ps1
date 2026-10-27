# ## Overview
# PowerShell script for uninstall.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Handles the removal and uninstallation process for the component 'etcd' stack.

.DESCRIPTION
Execute this script to remove etcd and its associated configurations from the system.
#>

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


#!/usr/bin/env pwsh
Write-Host "Uninstalling etcd..."
libscript_uninstall_pkg -Packages @("etcd")
