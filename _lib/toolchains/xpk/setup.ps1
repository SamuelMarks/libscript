# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'xpk' stack.

.DESCRIPTION
Execute this script to install and configure xpk on the local system.
#>

$ErrorActionPreference = "Stop"

$Action = if ($env:ACTION) { $env:ACTION } elseif ($args.Count -gt 0 -and $args[0] -notlike "-*") { $args[0] } else { "install" }
$XpkVersion = if ($env:XPK_VERSION) { $env:XPK_VERSION } elseif ($env:VERSION) { $env:VERSION } else { "latest" }
$CompVersion = $XpkVersion
$InstallMethod = if ($env:XPK_INSTALL_METHOD) { $env:XPK_INSTALL_METHOD } elseif ($env:LIBSCRIPT_DEFAULT_INSTALL_METHOD) { $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD } elseif ($env:LIBSCRIPT_GLOBAL_INSTALL_METHOD) { $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD } else { "libscript_native" }
$LibscriptRootDir = if ([string]::IsNullOrEmpty($env:LIBSCRIPT_ROOT_DIR)) { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path } else { $env:LIBSCRIPT_ROOT_DIR }
$LibscriptHome = if ($env:LIBSCRIPT_HOME) { $env:LIBSCRIPT_HOME } else { Join-Path $HOME ".libscript" }
$DownloadDir = if ($env:LIBSCRIPT_DOWNLOAD_DIR) { $env:LIBSCRIPT_DOWNLOAD_DIR } elseif ($env:DOWNLOAD_DIR) { $env:DOWNLOAD_DIR } else { Join-Path $LibscriptRootDir "cache\downloads" }

$Prefix = $env:PREFIX
if ([string]::IsNullOrEmpty($Prefix)) {
    $Prefix = Join-Path (Join-Path $LibscriptHome "xpk") $XpkVersion
}

if ($Action -eq "install") {
$BinDir = "$Prefix\bin"
if (-not (Test-Path -Path $BinDir)) {
    New-Item -ItemType Directory -Path $BinDir -Force | Out-Null
}

$ExePath = "$BinDir\xpk.cmd"

if (-not (Test-Path -Path $ExePath)) {
    Write-Host "Installing xpk into a virtual environment at $Prefix ..."
    
    if (-not (Get-Command "python" -ErrorAction SilentlyContinue)) {
        Write-Host "Python not found. Please install Python."
        exit 1
    }

    $PythonEnvCmd = Join-Path $LibscriptRootDir "engine\common\python_env.cmd"
    & cmd.exe /c "call `"$PythonEnvCmd`" libscript_python_venv `"$Prefix\venv`""
    if ($LASTEXITCODE -ne 0) { throw "Virtual environment creation failed." }
    
    if ($XpkVersion -eq "latest") {
        & "$Prefix\venv\Scripts\pip.exe" install xpk
    } else {
        & "$Prefix\venv\Scripts\pip.exe" install "xpk==$XpkVersion"
    }

    $CmdContent = @"
@echo off
set "VENV_DIR=%~dp0..\venv"
"%VENV_DIR%\Scripts\xpk.exe" %*
"@
    Set-Content -Path $ExePath -Value $CmdContent

    Write-Host "xpk installed to $ExePath"
} else {
    Write-Host "xpk already installed at $ExePath"
}

$GcpProj = if ($env:LIBSCRIPT_GCP_PROJECT_ID) { $env:LIBSCRIPT_GCP_PROJECT_ID } else { $env:GCP_PROJECT_ID }
if (-not ([string]::IsNullOrEmpty($GcpProj))) {
    & $ExePath config set project $GcpProj
}
if (-not ([string]::IsNullOrEmpty($env:GCP_ZONE))) {
    & $ExePath config set zone $env:GCP_ZONE
}
$XpkCluster = if ($env:LIBSCRIPT_XPK_CLUSTER_NAME) { $env:LIBSCRIPT_XPK_CLUSTER_NAME } else { $env:XPK_CLUSTER_NAME }
if (-not ([string]::IsNullOrEmpty($XpkCluster))) {
    & $ExePath config set cluster $XpkCluster
}
exit 0
}

if ($Action -eq "ls") {
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "xpk"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    Write-Output "ls-remote not fully implemented natively yet."
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    Write-Output "Native 'use' requires symlink support which is partially implemented."
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading xpk to $DownloadDir\xpk..."
    }
    exit 0
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "engine\common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_xpk" }
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
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_xpk" }
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
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_xpk" }
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
        Write-Output "Uninstalling xpk $CompVersion..."
        if (-not $LibscriptHome) { $LibscriptHome = Join-Path $HOME ".libscript" }
        $TargetDir = Join-Path (Join-Path $LibscriptHome "xpk") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for `$InstallMethod."
    }
    exit 0
}
