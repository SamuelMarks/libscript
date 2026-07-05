<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'ollama' stack.

.DESCRIPTION
Execute this script to install and configure ollama on the local system.
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

if ($Action -eq "start") {
    Write-Output "start not natively implemented for ollama yet."
    exit 0
}

if ($Action -eq "stop") {
    Write-Output "stop not natively implemented for ollama yet."
    exit 0
}

if ($Action -eq "install-service") {
    Write-Output "install-service not natively implemented for ollama yet."
    exit 0
}

if ($Action -eq "uninstall-service") {
    Write-Output "uninstall-service not natively implemented for ollama yet."
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling ollama $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "ollama") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for $InstallMethod."
    }
    exit 0
}
