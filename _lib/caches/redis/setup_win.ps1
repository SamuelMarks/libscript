[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$RedisVersion = $env:REDIS_VERSION
if ([string]::IsNullOrEmpty($RedisVersion)) {
    $RedisVersion = "latest"
}

$PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($PkgMgr)) {
    $PkgMgr = "winget"
}
if ($PkgMgr -eq "winget") {
    winget install Microsoft.Redis
} elseif ($PkgMgr -eq "choco") {
    choco install redis-64
} else {
    Write-Error "Unsupported Windows package manager: $PkgMgr"
}
