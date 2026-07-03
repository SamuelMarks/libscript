<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'java' stack.

.DESCRIPTION
Execute this script to install and configure java on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:JAVA_INSTALL_METHOD
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

$JavaVersion = $env:JAVA_VERSION
if ([string]::IsNullOrEmpty($JavaVersion)) {
    $JavaVersion = "17"
}
if ($JavaVersion -eq "latest") {
    $JavaVersion = "21"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls java
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            java -version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $JavaDir = Join-Path $LibscriptHome "java"
            if (Test-Path $JavaDir) {
                Get-ChildItem -Path $JavaDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote java
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            Write-Host "8`n11`n17`n21`n22"
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "java@${JavaVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            Set-LibscriptAlias -Component "java" -AliasName $JavaVersion -ExactVersion $JavaVersion
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
                winget install --silent --force --id=Microsoft.OpenJDK.17 -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y openjdk17
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "java@${JavaVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $JavaDir = Get-LibscriptVersionDir -Component "java" -Version $JavaVersion
            $JavaExe = Join-Path $JavaDir "bin\java.exe"

            if (Test-Path $JavaExe) {
                $InstalledVersion = & $JavaExe -version 2>&1
                if ($InstalledVersion -match "`"$JavaVersion") {
                    Write-Host "Java $JavaVersion is already installed."
                    Set-LibscriptAlias -Component "java" -AliasName $JavaVersion -ExactVersion $JavaVersion
                    return
                }
            }

            $Arch = "x64"
            if ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
                $Arch = "x86"
            } elseif ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
                $Arch = "aarch64"
            }

            $DownloadUrl = "https://api.adoptium.net/v3/binary/latest/${JavaVersion}/ga/windows/${Arch}/jdk/hotspot/normal/eclipse"

            if (-not (Test-Path $JavaDir)) {
                New-Item -ItemType Directory -Force -Path $JavaDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "java-$JavaVersion.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $JavaDir"
            Expand-Archive -Path $TempZip -DestinationPath $JavaDir -Force
            
            $NestedDir = Get-ChildItem -Path $JavaDir -Directory | Select-Object -First 1
            if ($NestedDir) {
                Move-Item -Path "$($NestedDir.FullName)\*" -Destination $JavaDir -Force
                Remove-Item -Recurse -Force $NestedDir.FullName
            }
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "java" -AliasName $JavaVersion -ExactVersion $JavaVersion
        }
        break
    }
}
