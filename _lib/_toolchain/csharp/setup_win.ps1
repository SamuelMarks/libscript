#!/usr/bin/env pwsh

$InstallMethod = $env:CSHARP_INSTALL_METHOD
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
    winget install --silent --force --id=Microsoft.DotNet.SDK.8 -e --accept-package-agreements --accept-source-agreements
} elseif ($InstallMethod -eq "system" -and $WinPkgMgr -eq "choco") {
    choco install -y Microsoft.DotNet.SDK.8
} else {
    Write-Host "From-source or alternative Windows package manager requested for csharp."
    winget install --silent --force --id=Microsoft.DotNet.SDK.8 -e --accept-package-agreements --accept-source-agreements
}
