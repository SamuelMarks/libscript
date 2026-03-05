#!/usr/bin/env pwsh

$InstallMethod = $env:GO_INSTALL_METHOD
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
    $WinPkgMgr install --silent --force --id=GoLang.Go -e --accept-package-agreements --accept-source-agreements
} elseif ($InstallMethod -eq "system" -and $WinPkgMgr -eq "choco") {
    choco install -y GoLang.Go
} else {
    Write-Host "From-source or alternative Windows package manager requested for go."
    winget install --silent --force --id=GoLang.Go -e --accept-package-agreements --accept-source-agreements
}
