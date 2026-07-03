<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'openbao' stack.

.DESCRIPTION
Execute this script to install and configure openbao on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:OPENBAO_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript-native"
}

$WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($WinPkgMgr)) {
    $WinPkgMgr = "winget"
}

if ($InstallMethod -eq "system" -and $WinPkgMgr -eq "winget") {
    winget install --silent --force --id=openbao.openbao -e --accept-package-agreements --accept-source-agreements
} elseif ($InstallMethod -eq "system" -and $WinPkgMgr -eq "choco") {
    choco install -y openbao
} else {
    Write-Host "From-source or alternative Windows package manager requested for openbao."
    winget install --silent --force --id=openbao.openbao -e --accept-package-agreements --accept-source-agreements
}
