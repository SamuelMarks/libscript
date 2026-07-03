<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'php' stack.

.DESCRIPTION
Execute this script to install and configure php on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:PHP_INSTALL_METHOD
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

$PhpVersion = $env:PHP_VERSION
if ([string]::IsNullOrEmpty($PhpVersion)) {
    $PhpVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($PhpVersion -eq "latest") {
        $ExactVersion = "8.3.11"
    } else {
        $ExactVersion = $PhpVersion
    }
    
    $Arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
        $Arch = "x86"
    }

    return @{ ExactVersion = $ExactVersion; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls php
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            php -v
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $PhpDir = Join-Path $LibscriptHome "php"
            if (Test-Path $PhpDir) {
                Get-ChildItem -Path $PhpDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote php
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            Write-Host "8.2.23`n8.3.11"
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "php@${PhpVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "php" -AliasName $PhpVersion -ExactVersion $Info.ExactVersion
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
                winget install --silent --force --id=PHP.PHP -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y php
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "php@${PhpVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $Arch = $Info.Arch

            $PhpDir = Get-LibscriptVersionDir -Component "php" -Version $ExactVersion
            $PhpExe = Join-Path $PhpDir "php.exe"

            if (Test-Path $PhpExe) {
                $InstalledVersion = & $PhpExe -v
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "PHP $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "php" -AliasName $PhpVersion -ExactVersion $ExactVersion
                    return
                }
            }

            # On Windows, PHP provides Thread Safe (TS) and Non Thread Safe (NTS) versions.
            # We will default to NTS x64 as it is common for fastcgi.
            $ZipName = "php-$ExactVersion-nts-Win32-vs16-$Arch.zip"
            $DownloadUrl = "https://windows.php.net/downloads/releases/$ZipName"

            if (-not (Test-Path $PhpDir)) {
                New-Item -ItemType Directory -Force -Path $PhpDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() $ZipName
            Write-Host "Downloading $DownloadUrl"
            try {
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip
            } catch {
                Write-Host "Failed to download PHP. The version might not exist or the URL changed."
                throw
            }

            Write-Host "Extracting $TempZip to $PhpDir"
            Expand-Archive -Path $TempZip -DestinationPath $PhpDir -Force
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "php" -AliasName $PhpVersion -ExactVersion $ExactVersion
        }
        break
    }
}
