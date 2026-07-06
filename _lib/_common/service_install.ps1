<#
.SYNOPSIS
Internal script for service_install on Windows.

.DESCRIPTION
Executes initialization, logic, or testing for service_install.
#>

# LibScript Service Installer for Windows
param(
    [string]$ServiceName,
    [string]$ExecStart,
    [string]$WorkingDir,
    [string]$Description,
    [switch]$Uninstall
)

if (-not $ServiceName) {
    Write-Error "ServiceName is required"
    exit 1
}

if ($Uninstall) {
    Write-Output "Uninstalling Windows service: $ServiceName"
    sc.exe stop $ServiceName
    sc.exe delete $ServiceName
    exit 0
}

if (-not $Description) {
    $Description = "$ServiceName service"
}

Write-Output "Installing Windows service: $ServiceName"
sc.exe create $ServiceName binPath= $ExecStart start= auto obj= LocalSystem
sc.exe description $ServiceName $Description
