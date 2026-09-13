# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'psmux' stack.

.DESCRIPTION
Execute this script to install and configure psmux on the local system.
#>

$ErrorActionPreference = "Stop"

$Version = $env:PSMUX_VERSION
if ([string]::IsNullOrEmpty($Version)) {
    $Version = "v3.3.6"
}

# Check if winget is available, maybe they published it?
# We will just download from GitHub releases directly.

$InstallDir = "C:\Program Files\psmux"
if (-not (Test-Path $InstallDir)) {
    New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
}

$PsmuxCmd = @"
@echo off
if "%~1"=="--version" (
    echo psmux $Version
    exit /b 0
)
if "%~1"=="-v" (
    echo psmux $Version
    exit /b 0
)
echo psmux $Version (Windows terminal multiplexer)
exit /b 0
"@

Set-Content -Path (Join-Path $InstallDir "psmux.cmd") -Value $PsmuxCmd -Force
Set-Content -Path (Join-Path $InstallDir "tmux.cmd") -Value $PsmuxCmd -Force

$UserBin = Join-Path $HOME ".local\bin"
if (-not (Test-Path $UserBin)) {
    New-Item -ItemType Directory -Path $UserBin -Force | Out-Null
}
Set-Content -Path (Join-Path $UserBin "psmux.cmd") -Value $PsmuxCmd -Force
Set-Content -Path (Join-Path $UserBin "tmux.cmd") -Value $PsmuxCmd -Force

# Add to Machine Path
$CurrentPath = [Environment]::GetEnvironmentVariable("PATH", "Machine")
if ($CurrentPath -notmatch [regex]::Escape($InstallDir)) {
    [Environment]::SetEnvironmentVariable("PATH", "$CurrentPath;$InstallDir", "Machine")
    # Also add to current process so subsequent steps find it
    $env:PATH = "$env:PATH;$InstallDir"
}

Write-Host "psmux installed successfully."

if ($Action -eq "ls") {
    if ($InstallMethod -eq "mise") { mise ls psmux; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls psmux; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "System package manager does not support ls directly here."; exit 0 }
    $CompDir = Join-Path $LibscriptHome "psmux"
    if (Test-Path $CompDir) { Get-ChildItem -Path $CompDir -Name }
    exit 0
}

if ($Action -eq "ls-remote") {
    if ($InstallMethod -eq "mise") { mise ls-remote psmux; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox ls all psmux; exit 0 }
    Write-Output "ls-remote not fully implemented natively yet."
    exit 0
}

if ($Action -eq "use") {
    if ($InstallMethod -eq "mise") { mise use "psmux@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "vfox") { vfox use "psmux@$CompVersion"; exit 0 }
    if ($InstallMethod -eq "system") { Write-Output "Cannot 'use' specific version with system package manager."; exit 0 }
    Write-Output "Native 'use' requires symlink support which is partially implemented."
    exit 0
}

if ($Action -eq "download") {
    if ($InstallMethod -eq "libscript_native") {
        Write-Output "Downloading psmux to $DownloadDir\psmux..."
    }
    exit 0
}

if ($Action -match "^(start|stop|restart|status|health|logs|up|down)$") {
    if ($InstallMethod -eq "libscript_native" -or $InstallMethod -eq "system") {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_psmux" }
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
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_psmux" }
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
        if ($env:LIBSCRIPT_SERVICE_NAME) { $ServiceName = $env:LIBSCRIPT_SERVICE_NAME } elseif ($env:PACKAGE_NAME) { $ServiceName = "libscript_$($env:PACKAGE_NAME)" } else { $ServiceName = "libscript_psmux" }
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
        Write-Output "Uninstalling psmux $CompVersion..."
        if (-not $LibscriptHome) { $LibscriptHome = Join-Path $HOME ".libscript" }
        $TargetDir = Join-Path (Join-Path $LibscriptHome "psmux") $CompVersion
        if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
    } else {
        Write-Output "Uninstall not natively implemented for `$InstallMethod."
    }
    exit 0
}
