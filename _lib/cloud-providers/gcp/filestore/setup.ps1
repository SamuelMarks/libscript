<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'filestore' stack.

.DESCRIPTION
Execute this script to install and configure filestore on the local system.
#>

$ErrorActionPreference = "Stop"

$GcpCliVersion = $env:GCP_CLI_VERSION
if ([string]::IsNullOrEmpty($GcpCliVersion)) {
    $GcpCliVersion = "latest"
}

$InstallMethod = $env:GCP_CLI_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript_native"
}

if ($InstallMethod -eq "system") {
    $PkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
    if ([string]::IsNullOrEmpty($PkgMgr)) {
        $PkgMgr = "winget"
    }
    if ($PkgMgr -eq "winget") {
        winget install Google.CloudSDK
    } elseif ($PkgMgr -eq "choco") {
        choco install gcloudsdk
    } else {
        Write-Error "Unsupported Windows package manager: $PkgMgr"
    }
} else {
    $Prefix = $env:PREFIX
    if ([string]::IsNullOrEmpty($Prefix)) {
        $LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { "C:\libscript" } else { $env:LIBSCRIPT_ROOT_DIR }
        $Prefix = "$LibscriptRootDir\installed\gcp-cli"
    }

    if ($GcpCliVersion -eq "latest") {
        $GcpCliVersion = "476.0.0"
    }

    if (-not (Test-Path -Path "$Prefix\bin\gcloud.cmd")) {
        $Url = "https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-${GcpCliVersion}-windows-x86_64.zip"

        Write-Host "Downloading GCP CLI from $Url ..."
        $ZipPath = "$Prefix\google-cloud-cli.zip"
        
        if (-not (Test-Path -Path $Prefix)) {
            New-Item -ItemType Directory -Path $Prefix -Force | Out-Null
        }

        Invoke-WebRequest -Uri $Url -OutFile $ZipPath -UseBasicParsing
        Write-Host "Extracting archive..."
        Expand-Archive -Path $ZipPath -DestinationPath $Prefix -Force
        Remove-Item -Path $ZipPath

        $ExtractedFolder = "$Prefix\google-cloud-sdk"
        if (Test-Path -Path $ExtractedFolder) {
            Move-Item -Path "$ExtractedFolder\*" -Destination $Prefix -Force
            Remove-Item -Path $ExtractedFolder -Recurse
        }

        & "$Prefix\install.bat" --quiet
        & "$Prefix\bin\gcloud.cmd" components install alpha beta compute --quiet

        Write-Host "GCP CLI installed to $Prefix"
    } else {
        Write-Host "GCP CLI already installed at $Prefix\bin\gcloud.cmd"
    }

    $AuthOutput = & "$Prefix\bin\gcloud.cmd" auth print-access-token 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host "No valid auth found. Running gcloud auth login..."
        & "$Prefix\bin\gcloud.cmd" auth login
    }
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls gcp; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls gcp; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "gcp"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote gcp; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all gcp; exit 0 }
    Write-Output "ls-remote not fully implemented natively yet."
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "gcp@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    Write-Output "Native 'use' requires symlink support which is partially implemented."
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading gcp to $DownloadDir\gcp..."
    }
    exit 0
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        if (Get-Command libscript_service -ErrorAction SilentlyContinue) {
            libscript_service $Action $ServiceName
        } else {
            if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
                Libscript-Service -Action $Action -ServiceName $ServiceName @args
            } else { Write-Output "$Action not natively implemented for `$InstallMethod." }
        }
    } else {
        Write-Output "$Action not natively implemented for `$InstallMethod."
    }
    exit 0
}

if ($Action -eq "install-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        if (Get-Command libscript_install_service -ErrorAction SilentlyContinue) {
            libscript_install_service $ServiceName
        } else {
            if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
                Libscript-InstallService -ServiceName $ServiceName @args
            } else { Write-Output "install-service not implemented for `$InstallMethod." }
        }
    } else {
        Write-Output "install-service not implemented for `$InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall-service") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_gcp" }
        if (Get-Command libscript_uninstall_service -ErrorAction SilentlyContinue) {
            libscript_uninstall_service $ServiceName
        } else {
            if (Get-Command Libscript-UninstallService -ErrorAction SilentlyContinue) {
                Libscript-UninstallService -ServiceName $ServiceName @args
            } else { Write-Output "uninstall-service not implemented for `$InstallMethod." }
        }
    } else {
        Write-Output "uninstall-service not implemented for `$InstallMethod."
    }
    exit 0
}

if ($Action -eq "uninstall") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Uninstalling gcp $CompVersion..."
        if (-not $LibscriptHome) { $LibscriptHome = Join-Path $HOME ".libscript" }
        $TargetDir = Join-Path (Join-Path $LibscriptHome "gcp") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for `$InstallMethod."
    }
    exit 0
}
