[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$MosquittoVersion = $env:MOSQUITTO_VERSION
if ([string]::IsNullOrEmpty($MosquittoVersion)) {
    $MosquittoVersion = "latest"
}

$PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($PkgMgr)) {
    $PkgMgr = "winget"
}
if ($PkgMgr -eq "winget") {
    winget install EclipseFoundation.Mosquitto
} elseif ($PkgMgr -eq "choco") {
    choco install mosquitto
} else {
    Write-Error "Unsupported Windows package manager: $PkgMgr"
}
