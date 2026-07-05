<#
.SYNOPSIS
Windows PowerShell setup stub for gcp

.DESCRIPTION
Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
#>

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

$CompVersion = $env:GCP_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) { $CompVersion = "latest" }

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$DownloadDir = $env:DOWNLOAD_DIR
if ([string]::IsNullOrEmpty($DownloadDir)) {
    $DownloadDir = Join-Path $env:TEMP "libscript_downloads"
}

$InstallMethod = $env:GCP_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    if (-not [string]::IsNullOrEmpty($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD)) {
        $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
    } else {
        $InstallMethod = "libscript_native"
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls gcp; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf list gcp; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not have a local list command"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls gcp; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "gcp"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote gcp; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf list all gcp; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not have a local list command"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all gcp; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls-remote directly here."; exit 0 }
    if ($env:GCP_RELEASES_URL) {
        Invoke-WebRequest -Uri $env:GCP_RELEASES_URL | Select-Object -ExpandProperty Content
    } else {
        Write-Output "ls-remote not fully implemented natively yet."
    }
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf global gcp "$CompVersion"; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not use explicit versions this way"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    
if ($CompVersion -eq "latest" -or $CompVersion -eq "lts") {
    $ExactVersion = $CompVersion
} else {
    $ExactVersion = $CompVersion
}
if ([string]::IsNullOrEmpty($ExactVersion)) { $ExactVersion = $CompVersion }

$TargetDir = Join-Path (Join-Path $LibscriptHome "gcp") $ExactVersion
$AliasDir = Join-Path (Join-Path $LibscriptHome "gcp") $CompVersion

    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading gcp $CompVersion to $DownloadDir\gcp..."
        $CompDownloadDir = Join-Path $DownloadDir "gcp"
        if (-not (Test-Path $CompDownloadDir)) {
            New-Item -ItemType Directory -Force -Path $CompDownloadDir | Out-Null
        }
        if ($env:GCP_DOWNLOAD_URL) {
            Invoke-WebRequest -Uri $env:GCP_DOWNLOAD_URL -OutFile "$CompDownloadDir\gcp-$CompVersion.zip"
        } else {
            Write-Output "GCP_DOWNLOAD_URL is not defined. Skipping."
        }
    }
    exit 0
}

if ($Action -eq "install") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager installation not implemented natively in ps1 yet."; exit 0 }
    if ($InstallMethod -eq "mise") { mise install "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf install gcp "$CompVersion"; exit 0 }
    if ($InstallMethod -eq "pkgx") { pkgx install "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox add gcp; vfox install "gcp@$CompVersion"; exit 0 }

    $TargetDir = Join-Path (Join-Path $LibscriptHome "gcp") $CompVersion
    $TargetBin = Join-Path $TargetDir "bin"
    if (-not (Test-Path $TargetBin)) {
        Write-Output "Installing gcp $CompVersion natively to $TargetDir..."
        New-Item -ItemType Directory -Force -Path $TargetBin | Out-Null
        $CacheFileZip = "$DownloadDir\gcp\gcp-$CompVersion.zip"
        $CacheFileTar = "$DownloadDir\gcp\gcp-$CompVersion.tar.gz"
        if (Test-Path $CacheFileZip) {
            Write-Output "Extracting from cache..."
            Expand-Archive -Path $CacheFileZip -DestinationPath $TargetDir -Force
        } elseif (Test-Path $CacheFileTar) {
            Write-Output "Extracting from cache..."
            tar -xf $CacheFileTar -C $TargetDir
        } elseif ($env:GCP_DOWNLOAD_URL) {
            Write-Output "Downloading and extracting..."
            $TempFile = Join-Path $env:TEMP "gcp.zip"
            Invoke-WebRequest -Uri $env:GCP_DOWNLOAD_URL -OutFile $TempFile
            Expand-Archive -Path $TempFile -DestinationPath $TargetDir -Force
        } else {
            Write-Output "No download URL or cache available for gcp."
        }
    } else {
        Write-Output "gcp $CompVersion is already installed."
    }
    
    $AliasDir = Join-Path (Join-Path $LibscriptHome "gcp") $CompVersion
    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        libscript_service $Action $ServiceName
    } else {
        Write-Output "$Action not natively implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        libscript_install_service $ServiceName
    } else {
        Write-Output "install-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        libscript_uninstall_service $ServiceName
    } else {
        Write-Output "uninstall-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling gcp $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "gcp") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for $InstallMethod."
    }
    exit 0
}
