<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'redis' stack.

.DESCRIPTION
Execute this script to install and configure redis on the local system.
#>

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
