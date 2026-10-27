# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Windows PowerShell setup stub for redis

.DESCRIPTION
Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
#>

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

$CompVersion = $env:REDIS_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) { $CompVersion = "latest" }

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$DownloadDir = $env:DOWNLOAD_DIR
if ([string]::IsNullOrEmpty($DownloadDir)) {
    $DownloadDir = Join-Path $env:TEMP "libscript_downloads"
}

$InstallMethod = $env:REDIS_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    if (-not [string]::IsNullOrEmpty($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD)) {
        $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
    } else {
        $InstallMethod = "libscript_native"
    }
}

if ([string]::IsNullOrEmpty($env:REDIS_DOWNLOAD_URL)) {
    $tmpVer = $CompVersion
    if ($tmpVer -eq "latest") {
        $tags = git ls-remote --tags "https://github.com/SamuelMarks/redis-windows" 2>$null | Select-String -Pattern '\d+\.\d+\.\d+' -AllMatches | ForEach-Object { $_.Matches.Value }
        if ($tags) {
            $tmpVer = $tags | Sort-Object {[version]$_} | Select-Object -Last 1
        }
    }
    if ($tmpVer -ne "latest" -and -not [string]::IsNullOrEmpty($tmpVer)) {
        $env:REDIS_DOWNLOAD_URL = "https://github.com/SamuelMarks/redis-windows/releases/download/$tmpVer/redis-$tmpVer-win64.zip"
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "redis"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls-remote directly here."; exit 0 }
    if ($env:REDIS_RELEASES_URL) {
        Invoke-LibscriptFetchContent -Uri $env:REDIS_RELEASES_URL
    } else {
        $tags = git ls-remote --tags "https://github.com/SamuelMarks/redis-windows" 2>$null | Select-String -Pattern '\d+\.\d+\.\d+' -AllMatches | ForEach-Object { $_.Matches.Value }
        if ($tags) {
            $tags | Sort-Object {[version]$_}
        }
    }
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    
if ($CompVersion -eq "latest" -or $CompVersion -eq "lts") {
    $ExactVersion = $CompVersion
} else {
    $ExactVersion = $CompVersion
}
if ([string]::IsNullOrEmpty($ExactVersion)) { $ExactVersion = $CompVersion }

$TargetDir = Join-Path (Join-Path $LibscriptHome "redis") $ExactVersion
$AliasDir = Join-Path (Join-Path $LibscriptHome "redis") $CompVersion

    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading redis $CompVersion to $DownloadDir\redis..."
        $CompDownloadDir = Join-Path $DownloadDir "redis"
        if (-not (Test-Path $CompDownloadDir)) {
            New-Item -ItemType Directory -Force -Path $CompDownloadDir | Out-Null
        }
        if ($env:REDIS_DOWNLOAD_URL) {
            libscript_download $env:REDIS_DOWNLOAD_URL "$CompDownloadDir\redis-$CompVersion.zip"
        } else {
            Write-Output "REDIS_DOWNLOAD_URL is not defined. Skipping."
        }
    }
    exit 0
}

if ($Action -eq "install") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager installation not implemented natively in ps1 yet."; exit 0 }

    $TargetDir = Join-Path (Join-Path $LibscriptHome "redis") $CompVersion
    $TargetBin = Join-Path $TargetDir "bin"
    if (-not (Test-Path $TargetBin)) {
        Write-Output "Installing redis $CompVersion natively to $TargetDir..."
        New-Item -ItemType Directory -Force -Path $TargetBin | Out-Null
        $CacheFileZip = "$DownloadDir\redis\redis-$CompVersion.zip"
        $CacheFileTar = "$DownloadDir\redis\redis-$CompVersion.tar.gz"
        if (Test-Path $CacheFileZip) {
            Write-Output "Extracting from cache..."
            Expand-Archive -Path $CacheFileZip -DestinationPath $TargetDir -Force
        } elseif (Test-Path $CacheFileTar) {
            Write-Output "Extracting from cache..."
            tar -xf $CacheFileTar -C $TargetDir
        } elseif ($env:REDIS_DOWNLOAD_URL) {
            Write-Output "Downloading and extracting..."
            $TempFile = Join-Path $env:TEMP "redis.zip"
            libscript_download $env:REDIS_DOWNLOAD_URL $TempFile
            Expand-Archive -Path $TempFile -DestinationPath $TargetDir -Force
        } else {
            Write-Error "No download URL or cache available for redis."
            exit 1
        }
    } else {
        Write-Output "redis $CompVersion is already installed."
    }
    
    $AliasDir = Join-Path (Join-Path $LibscriptHome "redis") $CompVersion
    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_redis" }
        libscript_service $Action $ServiceName
    } else {
        Write-Output "$Action not natively implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_redis" }
        libscript_install_service $ServiceName
    } else {
        Write-Output "install-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_redis" }
        libscript_uninstall_service $ServiceName
    } else {
        Write-Output "uninstall-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling redis $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "redis") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for $InstallMethod."
    }
    exit 0
}
