# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'jetstream' stack.

.DESCRIPTION
Execute this script to install and configure jetstream on the local system.
#>

$ErrorActionPreference = "Stop"

$Action = if ($env:ACTION) { $env:ACTION } elseif ($args.Count -gt 0 -and $args[0] -notlike "-*") { $args[0] } else { "install" }
$CompVersion = if ($env:JETSTREAM_VERSION) { $env:JETSTREAM_VERSION } elseif ($env:VERSION) { $env:VERSION } else { "latest" }
$InstallMethod = if ($env:JETSTREAM_INSTALL_METHOD) { $env:JETSTREAM_INSTALL_METHOD } elseif ($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD) { $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD } elseif ($env:LIBSCRIPT_GLOBAL_INSTALL_METHOD) { $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD } else { "libscript_native" }
$LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path } else { $env:LIBSCRIPT_ROOT_DIR }
$LibscriptHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $HOME ".libscript" }
$DownloadDir = if ($env:LIBSCRIPT_DOWNLOAD_DIR) { $env:LIBSCRIPT_DOWNLOAD_DIR } elseif ($env:DOWNLOAD_DIR) { $env:DOWNLOAD_DIR } else { Join-Path $LibscriptRootDir "cache\downloads" }

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $Prefix = Join-Path (Join-Path $LibscriptHome "jetstream") $CompVersion
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "jetstream"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    Write-Output "latest"
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    Write-Output "Native 'use' requires symlink support which is partially implemented."
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading jetstream metadata to $DownloadDir\jetstream..."
    }
    exit 0
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "engine\common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_jetstream" }
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
        $ServiceScript = Join-Path $LibscriptRootDir "engine\common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_jetstream" }
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
        $ServiceScript = Join-Path $LibscriptRootDir "engine\common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_jetstream" }
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
        Write-Output "Uninstalling jetstream $CompVersion..."
        $TargetDir = Join-Path (Join-Path $LibscriptHome "jetstream") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for `$InstallMethod."
    }
    exit 0
}

$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\jetstream-serve.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Setting up JetStream remote TPU launcher at $Prefix ..."
    $CmdContent = @"
@echo off
setlocal
if "%JETSTREAM_REMOTE_TPU_HOST%"=="" (
    echo [ERROR] Cloud TPU JetStream requires a Linux Cloud TPU VM ^(local Windows hosts have no /dev/accel TPU device^). 1>&2
    echo [ERROR] Provision a TPU VM via libscript.cmd gcp-tpu-vm or set JETSTREAM_REMOTE_TPU_HOST. 1>&2
    exit /b 86
)
echo Forwarding JetStream launch to remote TPU host %JETSTREAM_REMOTE_TPU_HOST%...
ssh "%JETSTREAM_REMOTE_TPU_HOST%" "jetstream-serve %*"
exit /b %ERRORLEVEL%
"@
    Set-Content -Path $ExePath -Value $CmdContent
    Write-Host "JetStream launcher installed to $ExePath"
} else {
    Write-Host "JetStream launcher already installed at $ExePath"
}
