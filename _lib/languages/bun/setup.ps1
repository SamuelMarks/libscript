# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'bun' stack.

.DESCRIPTION
Execute this script to install and configure bun on the local system.
#>

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


#!/usr/bin/env pwsh

$InstallMethod = $env:BUN_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript_native"
}

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) {
    $Action = "install"
}

$BunVersion = $env:BUN_VERSION
if ([string]::IsNullOrEmpty($BunVersion)) {
    $BunVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

# ## Resolve-ExactVersion
# Resolves the requested version identifier to an exact release version string.
function Resolve-ExactVersion {
    if ($BunVersion -eq "latest") {
        try {
            $Resp = Invoke-LibscriptFetchJson -Uri "https://api.github.com/repos/oven-sh/bun/releases/latest"
            $ExactVersion = $Resp.tag_name.TrimStart('v')
        } catch {
            $ExactVersion = "1.1.20"
        }
    } elseif ($BunVersion -eq "canary") {
        $ExactVersion = "canary"
    } else {
        $ExactVersion = $BunVersion.TrimStart('v')
    }
    
    $Arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $Arch = "aarch64"
    }

    return @{ ExactVersion = $ExactVersion; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "system") {
            bun --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $BunDir = Join-Path $LibscriptHome "bun"
            if (Test-Path $BunDir) {
                Get-ChildItem -Path $BunDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-LibscriptFetchJson -Uri "https://api.github.com/repos/oven-sh/bun/releases"
            $Resp | Select-Object -First 30 | ForEach-Object { $_.tag_name.TrimStart('v') }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "bun" -AliasName $BunVersion -ExactVersion $Info.ExactVersion
        }
        break
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_bun" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_bun" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_bun" }
        if (Get-Command Libscript-UninstallService -ErrorAction SilentlyContinue) {
            Libscript-UninstallService -ServiceName $ServiceName @args
        } else { Write-Host "uninstall-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall" {
        if ($InstallMethod -eq "libscript_native") {
            if (Get-Command Resolve-ExactVersion -ErrorAction SilentlyContinue) {
                $Info = Resolve-ExactVersion
                $Exact = $Info.ExactVersion
            } else {
                $Exact = if ($Version) { $Version } else { "latest" }
            }
            Write-Host "Uninstalling bun `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "bun\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading bun..."
        }
        break
    }
    default {
        # download and install
        if ($InstallMethod -eq "system") {
            $WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
            if ([string]::IsNullOrEmpty($WinPkgMgr)) {
                $WinPkgMgr = "winget"
            }
            if ($WinPkgMgr -eq "winget") {
    libscript_depends @("Oven.Bun")
            } elseif ($WinPkgMgr -eq "choco") {
    libscript_depends @("bun")
            }
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $Arch = $Info.Arch

            $BunDir = Get-LibscriptVersionDir -Component "bun" -Version $ExactVersion
            $BunExe = Join-Path $BunDir "bin\bun.exe"

            if (Test-Path $BunExe) {
                $InstalledVersion = & $BunExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Bun $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "bun" -AliasName $BunVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $Target = "bun-windows-$Arch"
            if ($ExactVersion -eq "canary") {
                $DownloadUrl = "https://github.com/oven-sh/bun/releases/download/canary/$Target.zip?v=canary"
            } else {
                $DownloadUrl = "https://github.com/oven-sh/bun/releases/download/bun-v$ExactVersion/$Target.zip?v=$ExactVersion"
            }

            $BinDir = Join-Path $BunDir "bin"
            if (-not (Test-Path $BinDir)) {
                New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
            }

            $TempZip = Join-Path ([System.IO.Path]::GetTempPath()) "$Target.zip"
            Write-Host "Downloading $DownloadUrl"
            libscript_download $DownloadUrl $TempZip

            Write-Host "Extracting $TempZip to $BinDir"
            Expand-Archive -Path $TempZip -DestinationPath $BinDir -Force
            Move-Item -Path "$BinDir\$Target\bun.exe" -Destination $BinDir -Force
            Remove-Item -Recurse -Force "$BinDir\$Target"
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "bun" -AliasName $BunVersion -ExactVersion $ExactVersion
        }
        break
    }
}
