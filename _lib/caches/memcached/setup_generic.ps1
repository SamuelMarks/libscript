# ## Overview
# PowerShell script for setup_generic.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Windows PowerShell setup stub for memcached

.DESCRIPTION
Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
#>

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

$CompVersion = $env:MEMCACHED_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) { $CompVersion = "latest" }

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$DownloadDir = $env:DOWNLOAD_DIR
if ([string]::IsNullOrEmpty($DownloadDir)) {
    $DownloadDir = Join-Path $env:TEMP "libscript_downloads"
}

$InstallMethod = $env:MEMCACHED_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    if (-not [string]::IsNullOrEmpty($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD)) {
        $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
    } else {
        $InstallMethod = "libscript_native"
    }
}

if ([string]::IsNullOrEmpty($env:MEMCACHED_DOWNLOAD_URL)) {
    $tmpVer = $CompVersion
    if ($tmpVer -eq "latest") {
        $tags = git ls-remote --tags "https://github.com/SamuelMarks/memcached-windows" 2>$null | Select-String -Pattern '\d+\.\d+\.\d+' -AllMatches | ForEach-Object { $_.Matches.Value }
        if ($tags) {
            $tmpVer = $tags | Sort-Object {[version]$_} | Select-Object -Last 1
        } else {
            $tmpVer = "1.6.45"
        }
    }
    if ($tmpVer -ne "latest" -and -not [string]::IsNullOrEmpty($tmpVer)) {
        $env:MEMCACHED_DOWNLOAD_URL = "https://github.com/SamuelMarks/memcached-windows/releases/download/v$tmpVer/Memcached-$tmpVer-win64.zip"
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls memcached; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf list memcached; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not have a local list command"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls memcached; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "memcached"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote memcached; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf list all memcached; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not have a local list command"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all memcached; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls-remote directly here."; exit 0 }
    if ($env:MEMCACHED_RELEASES_URL) {
        Invoke-WebRequest -Uri $env:MEMCACHED_RELEASES_URL | Select-Object -ExpandProperty Content
    } else {
        $tags = git ls-remote --tags "https://github.com/SamuelMarks/memcached-windows" 2>$null | Select-String -Pattern '\d+\.\d+\.\d+' -AllMatches | ForEach-Object { $_.Matches.Value }
        if ($tags) {
            $tags | Sort-Object {[version]$_}
        }
    }
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "memcached@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf global memcached "$CompVersion"; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not use explicit versions this way"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "memcached@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    
    if ($CompVersion -eq "latest" -or $CompVersion -eq "lts") {
        $ExactVersion = "1.6.45"
    } else {
        $ExactVersion = $CompVersion
    }
    if ([string]::IsNullOrEmpty($ExactVersion)) { $ExactVersion = $CompVersion }

    $TargetDir = Join-Path (Join-Path $LibscriptHome "memcached") $ExactVersion
    $AliasDir = Join-Path (Join-Path $LibscriptHome "memcached") $CompVersion

    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading memcached $CompVersion to $DownloadDir\memcached..."
        $CompDownloadDir = Join-Path $DownloadDir "memcached"
        if (-not (Test-Path $CompDownloadDir)) {
            New-Item -ItemType Directory -Force -Path $CompDownloadDir | Out-Null
        }
        if ($env:MEMCACHED_DOWNLOAD_URL) {
            Invoke-WebRequest -Uri $env:MEMCACHED_DOWNLOAD_URL -OutFile "$CompDownloadDir\memcached-$CompVersion.zip"
        } else {
            Write-Output "MEMCACHED_DOWNLOAD_URL is not defined. Skipping."
        }
    }
    exit 0
}

if ($Action -eq "install") {
    if ($InstallMethod -eq "system") {
        Write-Output "System package manager installation via winget/choco..."
        winget install memcached --accept-package-agreements --accept-source-agreements
        exit $LASTEXITCODE
    }
    if ($InstallMethod -eq "mise") { mise install "memcached@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf install memcached "$CompVersion"; exit 0 }
    if ($InstallMethod -eq "pkgx") { pkgx install "memcached@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox add memcached; vfox install "memcached@$CompVersion"; exit 0 }

    $TargetDir = Join-Path (Join-Path $LibscriptHome "memcached") $CompVersion
    $TargetBin = Join-Path $TargetDir "bin"
    if (-not (Test-Path "$TargetBin\memcached.exe")) {
        Write-Output "Installing memcached $CompVersion natively to $TargetDir..."
        New-Item -ItemType Directory -Force -Path $TargetBin | Out-Null
        $CacheFileZip = "$DownloadDir\memcached\memcached-$CompVersion.zip"
        $CacheFileTar = "$DownloadDir\memcached\memcached-$CompVersion.tar.gz"
        if (Test-Path $CacheFileZip) {
            Write-Output "Extracting from cache..."
            Expand-Archive -Path $CacheFileZip -DestinationPath $TargetDir -Force
        } elseif (Test-Path $CacheFileTar) {
            Write-Output "Extracting from cache..."
            tar -xf $CacheFileTar -C $TargetDir
        } elseif ($env:MEMCACHED_DOWNLOAD_URL) {
            Write-Output "Downloading and extracting..."
            $TempFile = Join-Path $env:TEMP "memcached.zip"
            Invoke-WebRequest -Uri $env:MEMCACHED_DOWNLOAD_URL -OutFile $TempFile
            Expand-Archive -Path $TempFile -DestinationPath $TargetDir -Force
            Remove-Item -Force $TempFile -ErrorAction SilentlyContinue
        } else {
            Write-Error "No download URL or cache available for memcached."
            exit 1
        }
        $SubBin = Get-ChildItem -Path $TargetDir -Filter "bin" -Recurse -Directory | Where-Object { $_.FullName -ne $TargetBin } | Select-Object -First 1
        if ($SubBin -and -not (Test-Path "$TargetBin\memcached.exe")) {
            Copy-Item -Path "$($SubBin.FullName)\*" -Destination $TargetBin -Recurse -Force
        }
    } else {
        Write-Output "memcached $CompVersion is already installed."
    }
    
    $AliasDir = Join-Path (Join-Path $LibscriptHome "memcached") $CompVersion
    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $Root = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "..") "..")
        . (Join-Path $Root "_lib\_common\service.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_memcached" }
        libscript_service $Action $ServiceName
    } else {
        Write-Output "$Action not natively implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $Root = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "..") "..")
        . (Join-Path $Root "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_memcached" }
        libscript_install_service $ServiceName
    } else {
        Write-Output "install-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $Root = (Join-Path (Join-Path (Join-Path $PSScriptRoot "..") "..") "..")
        . (Join-Path $Root "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_memcached" }
        libscript_uninstall_service $ServiceName
    } else {
        Write-Output "uninstall-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling memcached $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "memcached") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for $InstallMethod."
    }
    exit 0
}
