<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'sh' stack.

.DESCRIPTION
Execute this script to install and configure sh on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:SH_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript-native"
}

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) {
    $Action = "install"
}

$ShVersion = $env:SH_VERSION
if ([string]::IsNullOrEmpty($ShVersion)) {
    $ShVersion = "0.5.12"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($ShVersion -eq "latest") {
        return "0.5.12"
    }
    return $ShVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls sh
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            sh --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $ShDir = Join-Path $LibscriptHome "sh"
            if (Test-Path $ShDir) {
                Get-ChildItem -Path $ShDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        Write-Host "0.5.12"
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "sh@${ShVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "sh" -AliasName $ShVersion -ExactVersion $ExactVersion
        }
        break
    }
    default {
        # download and install
        if ($InstallMethod -eq "system" -or $InstallMethod -eq "libscript-native") {
            $WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
            if ([string]::IsNullOrEmpty($WinPkgMgr)) {
                $WinPkgMgr = "winget"
            }
            if ($WinPkgMgr -eq "winget") {
                winget install --silent --force --id=MSYS2.MSYS2 -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y MSYS2.MSYS2
            }
        } else {
            Write-Host "mise/asdf do not support sh well on Windows."
        }
        break
    }
}
