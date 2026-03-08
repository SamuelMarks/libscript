[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$LighttpdVersion = $env:LIGHTTPD_VERSION
if ([string]::IsNullOrEmpty($LighttpdVersion)) {
    $LighttpdVersion = "latest"
}

$PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($PkgMgr)) {
    $PkgMgr = "winget"
}
if ($PkgMgr -eq "winget") {
    # Lighttpd natively doesn't have an official winget, sometimes found via third party
    Write-Host "[WARN] Lighttpd may not exist on winget natively, falling back to basic attempt."
    winget install lighttpd
} elseif ($PkgMgr -eq "choco") {
    choco install lighttpd
} else {
    Write-Error "Unsupported Windows package manager: $PkgMgr"
}
