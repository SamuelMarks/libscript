<#
.SYNOPSIS
## Overview
Provisions sparse disk images and configures partition tables on Linux.

## Usage
.\provision_disk.ps1 [OPTIONS]
#>

[CmdletBinding()]
param()

Write-Error "[ERROR] $($MyInvocation.MyCommand.Name) requires Linux kernel primitives (e.g., mount, losetup, chroot, unshare)."
Write-Host  "[ERROR] Direct native execution on Windows is unsupported for this sub-operation." -ForegroundColor Red
Write-Host  "[INFO]  Execute this operation within a Linux environment or via a builder worker." -ForegroundColor Yellow
exit 86
