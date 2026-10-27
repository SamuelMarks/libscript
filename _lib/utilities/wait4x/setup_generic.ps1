# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Windows PowerShell setup stub for wait4x

.DESCRIPTION
Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
#>

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

$CompVersion = $env:WAIT4X_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) { $CompVersion = "latest" }

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$DownloadDir = $env:DOWNLOAD_DIR
if ([string]::IsNullOrEmpty($DownloadDir)) {
    $DownloadDir = Join-Path $env:TEMP "libscript_downloads"
}

$InstallMethod = $env:WAIT4X_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    if (-not [string]::IsNullOrEmpty($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD)) {
        $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
    } else {
        $InstallMethod = "libscript_native"
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "wait4x"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls-remote directly here."; exit 0 }
    if ($env:WAIT4X_RELEASES_URL) {
        Invoke-LibscriptFetchContent -Uri $env:WAIT4X_RELEASES_URL
    } else {
        Write-Output "ls-remote not fully implemented natively yet."
    }
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    
if ($CompVersion -eq "latest" -or $CompVersion -eq "lts") {
    try {
        $response = Invoke-LibscriptFetchJson -Uri "https://api.github.com/repos/atkrad/wait4x/releases/latest"
        $ExactVersion = $response.tag_name -replace '^v',''
    } catch {
        Write-Warning "Failed to fetch latest version from GitHub API"
        $ExactVersion = $CompVersion
    }
} else {
    $ExactVersion = $CompVersion
}
if ([string]::IsNullOrEmpty($ExactVersion)) { $ExactVersion = $CompVersion }

$TargetDir = Join-Path (Join-Path $LibscriptHome "wait4x") $ExactVersion
$AliasDir = Join-Path (Join-Path $LibscriptHome "wait4x") $CompVersion

    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading wait4x $CompVersion to $DownloadDir\wait4x..."
        $CompDownloadDir = Join-Path $DownloadDir "wait4x"
        if (-not (Test-Path $CompDownloadDir)) {
            New-Item -ItemType Directory -Force -Path $CompDownloadDir | Out-Null
        }
        if ($env:WAIT4X_DOWNLOAD_URL) {
            libscript_download $env:WAIT4X_DOWNLOAD_URL "$CompDownloadDir\wait4x-$CompVersion.zip"
        } else {
            Write-Output "WAIT4X_DOWNLOAD_URL is not defined. Skipping."
        }
    }
    exit 0
}

if ($Action -eq "install") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager installation not implemented natively in ps1 yet."; exit 0 }

    $TargetDir = Join-Path (Join-Path $LibscriptHome "wait4x") $CompVersion
    $TargetBin = Join-Path $TargetDir "bin"
    if (-not (Test-Path $TargetBin)) {
        Write-Output "Installing wait4x $CompVersion natively to $TargetDir..."
        New-Item -ItemType Directory -Force -Path $TargetBin | Out-Null
        $CacheFileZip = "$DownloadDir\wait4x\wait4x-$CompVersion.zip"
        $CacheFileTar = "$DownloadDir\wait4x\wait4x-$CompVersion.tar.gz"
        if (Test-Path $CacheFileZip) {
            Write-Output "Extracting from cache..."
            Expand-Archive -Path $CacheFileZip -DestinationPath $TargetDir -Force
        } elseif (Test-Path $CacheFileTar) {
            Write-Output "Extracting from cache..."
            tar -xf $CacheFileTar -C $TargetDir
        } elseif ($env:WAIT4X_DOWNLOAD_URL) {
            Write-Output "Downloading and extracting..."
            $TempFile = Join-Path $env:TEMP "wait4x.zip"
            libscript_download $env:WAIT4X_DOWNLOAD_URL $TempFile
            Expand-Archive -Path $TempFile -DestinationPath $TargetDir -Force
        } else {
            Write-Error "No download URL or cache available for wait4x."
            exit 1
        }
    } else {
        Write-Output "wait4x $CompVersion is already installed."
    }
    
    $AliasDir = Join-Path (Join-Path $LibscriptHome "wait4x") $CompVersion
    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_wait4x" }
        libscript_service $Action $ServiceName
    } else {
        Write-Output "$Action not natively implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_wait4x" }
        libscript_install_service $ServiceName
    } else {
        Write-Output "install-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_wait4x" }
        libscript_uninstall_service $ServiceName
    } else {
        Write-Output "uninstall-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling wait4x $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "wait4x") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for $InstallMethod."
    }
    exit 0
}
