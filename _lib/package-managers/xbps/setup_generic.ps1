<#
.SYNOPSIS
Provides a generic, cross-platform setup mechanism for the component 'xbps' stack.

.DESCRIPTION
Execute this script to perform generic initialization steps for xbps.
#>

$ErrorActionPreference = "Stop"

# This is a placeholder for the native PowerShell component setup.

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) {
    $Action = "install"
}

switch ($Action) {
    "ls" {
        Write-Host "[ls] PowerShell list support not implemented natively for this component."
        break
    }
    "ls-remote" {
        Write-Host "[ls-remote] PowerShell ls-remote support not implemented natively for this component."
        break
    }
    "use" {
        Write-Host "[use] PowerShell use support not implemented natively for this component."
        break
    }
    default {
        Write-Host "PowerShell native installation not implemented."
        exit 1
    }
}
