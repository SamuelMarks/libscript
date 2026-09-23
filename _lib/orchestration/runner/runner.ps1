<#
.SYNOPSIS
## Overview
Executes commands within a target rootfs using Linux namespaces and chroot.

## Usage
.\runner.ps1 [OPTIONS]
#>

[CmdletBinding()]
param()

Write-Error "[ERROR] $($MyInvocation.MyCommand.Name) requires Linux kernel primitives (e.g., mount, losetup, chroot, unshare)."
Write-Host  "[ERROR] Direct native execution on Windows is unsupported for this sub-operation." -ForegroundColor Red
Write-Host  "[INFO]  Execute this operation within a Linux environment or via a builder worker." -ForegroundColor Yellow
exit 86
