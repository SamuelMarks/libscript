# ## Overview
# PowerShell script for setup.ps1.
#
# ## Usage
# Execute via PowerShell.

<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'ruby' stack.

.DESCRIPTION
Execute this script to install and configure ruby on the local system.
#>

$ErrorActionPreference = "Stop"
$_ls_root = if ($env:LIBSCRIPT_ROOT_DIR) { $env:LIBSCRIPT_ROOT_DIR } else { (Resolve-Path (Join-Path $PSScriptRoot "..\..\..")).Path }
. (Join-Path $_ls_root "_lib\_common\pkg_mgr.ps1")


#!/usr/bin/env pwsh

$InstallMethod = $env:RUBY_INSTALL_METHOD
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

$RubyVersion = $env:RUBY_VERSION
if ([string]::IsNullOrEmpty($RubyVersion)) {
    $RubyVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

# ## Resolve-ExactVersion
# Resolves the requested version identifier to an exact release version string.
function Resolve-ExactVersion {
    if ($RubyVersion -eq "latest" -or $RubyVersion -eq "stable") {
        $ExactVersion = "3.3.0"
        try {
            $Resp = Invoke-LibscriptFetchContent -Uri "https://cache.ruby-lang.org/pub/ruby/index.txt"
            $Lines = $Resp -split "`n"
            foreach ($Line in $Lines) {
                if ($Line -match "^ruby-(\d+\.\d+\.\d+).*") {
                    $ExactVersion = $matches[1]
                }
            }
        } catch {}
    } else {
        $ExactVersion = $RubyVersion
    }
    
    $Arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
        $Arch = "x86"
    }

    return @{ ExactVersion = $ExactVersion; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "system") {
            ruby --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $RubyDir = Join-Path $LibscriptHome "ruby"
            if (Test-Path $RubyDir) {
                Get-ChildItem -Path $RubyDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-LibscriptFetchContent -Uri "https://cache.ruby-lang.org/pub/ruby/index.txt"
            $Resp -split "`n" | Where-Object { $_ -match "^ruby-(\d+\.\d+\.\d+)" } | ForEach-Object { $matches[1] } | Sort-Object -Unique
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "ruby" -AliasName $RubyVersion -ExactVersion $Info.ExactVersion
        }
        break
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_ruby" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_ruby" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_ruby" }
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
            Write-Host "Uninstalling ruby `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "ruby\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading ruby..."
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
    libscript_depends @("RubyInstallerTeam.Ruby")
            } elseif ($WinPkgMgr -eq "choco") {
    libscript_depends @("ruby")
            }
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $Arch = $Info.Arch

            $RubyDir = Get-LibscriptVersionDir -Component "ruby" -Version $ExactVersion
            $RubyExe = Join-Path $RubyDir "bin\ruby.exe"

            if (Test-Path $RubyExe) {
                $InstalledVersion = & $RubyExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Ruby $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "ruby" -AliasName $RubyVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $ExeName = "rubyinstaller-$ExactVersion-1-$Arch.exe"
            $DownloadUrl = "https://github.com/oneclick/rubyinstaller2/releases/download/RubyInstaller-$ExactVersion-1/$ExeName"

            if (-not (Test-Path $RubyDir)) {
                New-Item -ItemType Directory -Force -Path $RubyDir | Out-Null
            }

            $TempExe = Join-Path ([System.IO.Path]::GetTempPath()) $ExeName
            Write-Host "Downloading $DownloadUrl"
            try {
                libscript_download $DownloadUrl $TempExe
            } catch {
                Write-Host "Failed to download RubyInstaller. You may need to specify an exact sub-version available on github."
                throw
            }

            Write-Host "Installing $TempExe to $RubyDir"
            Start-Process -FilePath $TempExe -ArgumentList "/verysilent /dir=`"$RubyDir`" /tasks=nomodpath" -Wait -NoNewWindow
            Remove-Item -Force $TempExe

            Set-LibscriptAlias -Component "ruby" -AliasName $RubyVersion -ExactVersion $ExactVersion
        }
        break
    }
}
