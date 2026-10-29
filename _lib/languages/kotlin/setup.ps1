# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'kotlin' stack.

.DESCRIPTION
Execute this script to install and configure kotlin on the local system.
#>

#!/usr/bin/env pwsh
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")

$InstallMethod = $env:KOTLIN_INSTALL_METHOD
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

$KotlinVersion = $env:KOTLIN_VERSION
if ([string]::IsNullOrEmpty($KotlinVersion)) {
    $KotlinVersion = "1.9.20"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

# ## Resolve-ExactVersion
# Resolves the requested version identifier to an exact release version string.
function Resolve-ExactVersion {
    if ($KotlinVersion -eq "latest") {
        return "1.9.20"
    }
    return $KotlinVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "system") {
            kotlin -version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $KotlinDir = Join-Path $LibscriptHome "kotlin"
            if (Test-Path $KotlinDir) {
                Get-ChildItem -Path $KotlinDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-LibscriptFetchJson -Uri "https://api.github.com/repos/JetBrains/kotlin/releases"
            $Resp | ForEach-Object { $_.tag_name.Replace("v", "") } | Select-Object -First 100
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "kotlin" -AliasName $KotlinVersion -ExactVersion $ExactVersion
        }
        break
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_kotlin" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "stop" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_kotlin" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "stop" -ServiceName $ServiceName @args
        } else { Write-Host "stop not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_kotlin" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_kotlin" }
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
            Write-Host "Uninstalling kotlin `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "kotlin\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading kotlin..."
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
    libscript_depends @("JetBrains.Kotlin")
            } elseif ($WinPkgMgr -eq "choco") {
    libscript_depends @("kotlin")
            }
        } else {
            $ExactVersion = Resolve-ExactVersion
            $KotlinDir = Get-LibscriptVersionDir -Component "kotlin" -Version $ExactVersion
            $KotlinExe = Join-Path $KotlinDir "bin\kotlin.bat"

            if (Test-Path $KotlinExe) {
                Set-LibscriptAlias -Component "kotlin" -AliasName $KotlinVersion -ExactVersion $ExactVersion
                return
            }

            $ZipName = "kotlin-compiler-$ExactVersion.zip"
            $DownloadUrl = "https://github.com/JetBrains/kotlin/releases/download/v$ExactVersion/$ZipName"

            if (-not (Test-Path $KotlinDir)) {
                New-Item -ItemType Directory -Force -Path $KotlinDir | Out-Null
            }

            $TempZip = Join-Path ([System.IO.Path]::GetTempPath()) $ZipName
            Write-Host "Downloading $DownloadUrl"
            libscript_download $DownloadUrl $TempZip

            Write-Host "Extracting $TempZip"
            Expand-Archive -Path $TempZip -DestinationPath $KotlinDir -Force
            # Zip has 'kotlinc' dir inside
            $NestedDir = Join-Path $KotlinDir "kotlinc"
            if (Test-Path $NestedDir) {
                Move-Item -Path "$NestedDir\*" -Destination $KotlinDir -Force
                Remove-Item -Recurse -Force $NestedDir
            }
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "kotlin" -AliasName $KotlinVersion -ExactVersion $ExactVersion
        }
        break
    }
}
