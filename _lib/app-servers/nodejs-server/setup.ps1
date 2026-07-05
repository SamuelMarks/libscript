<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'nodejs-server' stack.

.DESCRIPTION
Execute this script to install and configure nodejs-server on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$PSScriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path

# 1. Ensure Node.js is installed
$nodejsSetup = "$PSScriptRoot\..\nodejs\setup.ps1"
if (Test-Path $nodejsSetup) {
    Write-Host "Ensuring Node.js is installed..."
    & $nodejsSetup
}

# 2. Determine DEST
$dest = $env:NODEJS_SERVER_DEST
if (-not $dest) {
    $rand = -join ((97..122) | Get-Random -Count 8 | ForEach-Object {[char]$_})
    $dataDir = if ($env:LIBSCRIPT_DATA_DIR) { $env:LIBSCRIPT_DATA_DIR } else { "$env:TEMP\libscript_data" }
    if (-not (Test-Path $dataDir)) { New-Item -Path $dataDir -ItemType Directory }
    $dest = "$dataDir\$rand"
    New-Item -Path $dest -ItemType Directory
    Set-Content -Path "$dest\main.js" -Value "console.log('Hello from Node.js server');"
    Write-Host "Created sample Node.js app at $dest"
}

# 3. Install dependencies
if (Test-Path "$dest\package.json") {
    Write-Host "Installing dependencies in $dest..."
    Push-Location $dest
    if (Test-Path "yarn.lock") {
        yarn
    } elseif (Test-Path "pnpm-lock.yaml") {
        pnpm install
    } else {
        npm install
    }
    Pop-Location
}

Write-Host "Node.js server setup complete."

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls nodejs-server; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls nodejs-server; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "nodejs-server"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote nodejs-server; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all nodejs-server; exit 0 }
    Write-Output "ls-remote not fully implemented natively yet."
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "nodejs-server@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "nodejs-server@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    Write-Output "Native 'use' requires symlink support which is partially implemented."
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading nodejs-server to $DownloadDir\nodejs-server..."
    }
    exit 0
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_nodejs-server" }
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
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_nodejs-server" }
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
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_nodejs-server" }
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
        Write-Output "Uninstalling nodejs-server $CompVersion..."
        if (-not $LibscriptHome) { $LibscriptHome = Join-Path $HOME ".libscript" }
        $TargetDir = Join-Path (Join-Path $LibscriptHome "nodejs-server") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for `$InstallMethod."
    }
    exit 0
}
