# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'maven' stack.

.DESCRIPTION
Execute this script to install and configure maven on the local system.
#>

#!/usr/bin/env pwsh
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")

$InstallMethod = $env:MAVEN_INSTALL_METHOD
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

$MavenVersion = $env:MAVEN_VERSION
if ([string]::IsNullOrEmpty($MavenVersion)) {
    $MavenVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

# ## Resolve-ExactVersion
# Resolves the requested version identifier to an exact release version string.
function Resolve-ExactVersion {
    if ($MavenVersion -eq "latest") {
        return "3.9.6"
    }
    return $MavenVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "system") {
            mvn -version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $MavenDir = Join-Path $LibscriptHome "maven"
            if (Test-Path $MavenDir) {
                Get-ChildItem -Path $MavenDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = @{ Content = (Invoke-LibscriptFetchContent -Uri "https://archive.apache.org/dist/maven/maven-3/") }
            $Resp.Content -split "`n" | Where-Object { $_ -match 'href="(\d+\.\d+\.\d+)/"' } | ForEach-Object { $matches[1] }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "maven" -AliasName $MavenVersion -ExactVersion $ExactVersion
        }
        break
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_maven" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "stop" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_maven" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "stop" -ServiceName $ServiceName @args
        } else { Write-Host "stop not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_maven" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_maven" }
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
            Write-Host "Uninstalling maven `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "maven\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading maven..."
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
    libscript_depends @(\"Apache.Maven\")
            } elseif ($WinPkgMgr -eq "choco") {
    libscript_depends @(\"maven\")
            }
        } else {
            $ExactVersion = Resolve-ExactVersion
            $MavenDir = Get-LibscriptVersionDir -Component "maven" -Version $ExactVersion
            $MavenExe = Join-Path $MavenDir "bin\mvn.cmd"

            if (Test-Path $MavenExe) {
                Set-LibscriptAlias -Component "maven" -AliasName $MavenVersion -ExactVersion $ExactVersion
                return
            }

            $MajorVer = $ExactVersion.Split(".")[0]
            $ZipName = "apache-maven-$ExactVersion-bin.zip"
            $DownloadUrl = "https://archive.apache.org/dist/maven/maven-$MajorVer/$ExactVersion/binaries/$ZipName"

            if (-not (Test-Path $MavenDir)) {
                New-Item -ItemType Directory -Force -Path $MavenDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() $ZipName
            Write-Host "Downloading $DownloadUrl"
            libscript_download $DownloadUrl $TempZip

            Write-Host "Extracting $TempZip to $MavenDir"
            Expand-Archive -Path $TempZip -DestinationPath $MavenDir -Force
            # Maven zip extracts a folder named apache-maven-version
            $NestedDir = Join-Path $MavenDir "apache-maven-$ExactVersion"
            if (Test-Path $NestedDir) {
                Move-Item -Path "$NestedDir\*" -Destination $MavenDir -Force
                Remove-Item -Recurse -Force $NestedDir
            }
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "maven" -AliasName $MavenVersion -ExactVersion $ExactVersion
        }
        break
    }
}
