<#
.SYNOPSIS
Windows PowerShell setup stub for jq

.DESCRIPTION
Managed by libscript. Provides download, install, ls, ls-remote, use capabilities.
#>

$ErrorActionPreference = "Stop"

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) { $Action = "install" }

$CompVersion = $env:JQ_VERSION
if ([string]::IsNullOrEmpty($CompVersion)) { $CompVersion = "latest" }

$LibscriptHome = $env:LIBSCRIPT_HOME
if ([string]::IsNullOrEmpty($LibscriptHome)) {
    $LibscriptHome = Join-Path $env:USERPROFILE ".libscript"
}

$DownloadDir = $env:DOWNLOAD_DIR
if ([string]::IsNullOrEmpty($DownloadDir)) {
    $DownloadDir = Join-Path $env:TEMP "libscript_downloads"
}

$InstallMethod = $env:JQ_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    if (-not [string]::IsNullOrEmpty($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD)) {
        $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
    } else {
        $InstallMethod = "libscript_native"
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls jq; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf list jq; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not have a local list command"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls jq; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "jq"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote jq; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf list all jq; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not have a local list command"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all jq; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls-remote directly here."; exit 0 }
    if ($env:JQ_RELEASES_URL) {
        Invoke-WebRequest -Uri $env:JQ_RELEASES_URL | Select-Object -ExpandProperty Content
    } else {
        Write-Output "ls-remote not fully implemented natively yet."
    }
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "jq@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf global jq "$CompVersion"; exit 0 }
    if ($InstallMethod -eq "pkgx") { Write-Output "pkgx does not use explicit versions this way"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "jq@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    
if ($CompVersion -eq "latest" -or $CompVersion -eq "lts") {
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/jqlang/jq/releases/latest" -ErrorAction Stop
        $ExactVersion = $response.tag_name -replace '^v',''
    } catch {
        Write-Warning "Failed to fetch latest version from GitHub API"
        $ExactVersion = $CompVersion
    }
} else {
    $ExactVersion = $CompVersion
}
if ([string]::IsNullOrEmpty($ExactVersion)) { $ExactVersion = $CompVersion }

$TargetDir = Join-Path (Join-Path $LibscriptHome "jq") $ExactVersion
$AliasDir = Join-Path (Join-Path $LibscriptHome "jq") $CompVersion

    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading jq $CompVersion to $DownloadDir\jq..."
        $CompDownloadDir = Join-Path $DownloadDir "jq"
        if (-not (Test-Path $CompDownloadDir)) {
            New-Item -ItemType Directory -Force -Path $CompDownloadDir | Out-Null
        }
        if ($env:JQ_DOWNLOAD_URL) {
            Invoke-WebRequest -Uri $env:JQ_DOWNLOAD_URL -OutFile "$CompDownloadDir\jq-$CompVersion.zip"
        } else {
            Write-Output "JQ_DOWNLOAD_URL is not defined. Skipping."
        }
    }
    exit 0
}

if ($Action -eq "install") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager installation not implemented natively in ps1 yet."; exit 0 }
    if ($InstallMethod -eq "mise") { mise install "jq@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "asdf") { asdf install jq "$CompVersion"; exit 0 }
    if ($InstallMethod -eq "pkgx") { pkgx install "jq@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox add jq; vfox install "jq@$CompVersion"; exit 0 }

    $TargetDir = Join-Path (Join-Path $LibscriptHome "jq") $CompVersion
    $TargetBin = Join-Path $TargetDir "bin"
    if (-not (Test-Path $TargetBin)) {
        Write-Output "Installing jq $CompVersion natively to $TargetDir..."
        New-Item -ItemType Directory -Force -Path $TargetBin | Out-Null
        $CacheFileZip = "$DownloadDir\jq\jq-$CompVersion.zip"
        $CacheFileTar = "$DownloadDir\jq\jq-$CompVersion.tar.gz"
        if (Test-Path $CacheFileZip) {
            Write-Output "Extracting from cache..."
            Expand-Archive -Path $CacheFileZip -DestinationPath $TargetDir -Force
        } elseif (Test-Path $CacheFileTar) {
            Write-Output "Extracting from cache..."
            tar -xf $CacheFileTar -C $TargetDir
        } elseif ($env:JQ_DOWNLOAD_URL) {
            Write-Output "Downloading and extracting..."
            $TempFile = Join-Path $env:TEMP "jq.zip"
            Invoke-WebRequest -Uri $env:JQ_DOWNLOAD_URL -OutFile $TempFile
            Expand-Archive -Path $TempFile -DestinationPath $TargetDir -Force
        } else {
            Write-Output "No download URL or cache available for jq."
        }
    } else {
        Write-Output "jq $CompVersion is already installed."
    }
    
    $AliasDir = Join-Path (Join-Path $LibscriptHome "jq") $CompVersion
    if ($AliasDir -ne $TargetDir) {
        if (Test-Path $AliasDir) { Remove-Item -Recurse -Force $AliasDir }
        New-Item -ItemType Junction -Path $AliasDir -Target $TargetDir | Out-Null
    }
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_jq" }
        libscript_service $Action $ServiceName
    } else {
        Write-Output "$Action not natively implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_jq" }
        libscript_install_service $ServiceName
    } else {
        Write-Output "install-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        . (Join-Path $LibscriptRoot "_lib\_common\service_install.ps1")
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_jq" }
        libscript_uninstall_service $ServiceName
    } else {
        Write-Output "uninstall-service not implemented for $InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling jq $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "jq") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for $InstallMethod."
    }
    exit 0
}
