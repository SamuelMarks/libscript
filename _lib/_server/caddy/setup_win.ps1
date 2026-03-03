#!/usr/bin/env pwsh

$InstallMethod = $env:CADDY_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "system"
}

$WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($WinPkgMgr)) {
    $WinPkgMgr = "winget"
}

if ($InstallMethod -eq "system" -and $WinPkgMgr -eq "winget") {
    winget install --id=caddy.caddy -e --accept-package-agreements --accept-source-agreements
} elseif ($InstallMethod -eq "system" -and $WinPkgMgr -eq "choco") {
    choco install -y caddy
} else {
    Write-Host "From-source or alternative Windows package manager requested for caddy."
    winget install --id=caddy.caddy -e --accept-package-agreements --accept-source-agreements
}