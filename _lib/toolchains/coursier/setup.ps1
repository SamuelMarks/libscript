<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'coursier' stack.

.DESCRIPTION
Execute this script to install and configure coursier on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:COURSIER_INSTALL_METHOD
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

$CoursierVersion = $env:COURSIER_VERSION
if ([string]::IsNullOrEmpty($CoursierVersion)) {
    $CoursierVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($CoursierVersion -eq "latest") {
        return "2.1.24"
    }
    return $CoursierVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls coursier
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            coursier --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $CoursierDir = Join-Path $LibscriptHome "coursier"
            if (Test-Path $CoursierDir) {
                Get-ChildItem -Path $CoursierDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote coursier
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/coursier/coursier/releases"
            $Resp | ForEach-Object { $_.tag_name.Replace("v", "") } | Select-Object -First 100
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "coursier@${CoursierVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "coursier" -AliasName $CoursierVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=Coursier.Coursier -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y coursier
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "coursier@${CoursierVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $CoursierDir = Get-LibscriptVersionDir -Component "coursier" -Version $ExactVersion
            $CoursierExe = Join-Path $CoursierDir "bin\coursier.exe"

            if (Test-Path $CoursierExe) {
                Set-LibscriptAlias -Component "coursier" -AliasName $CoursierVersion -ExactVersion $ExactVersion
                return
            }

            $Arch = "x86_64"
            $OsName = "pc-win32"

            $DownloadUrl = "https://github.com/coursier/coursier/releases/download/v$ExactVersion/cs-$Arch-$OsName.zip"

            $BinDir = Join-Path $CoursierDir "bin"
            if (-not (Test-Path $BinDir)) {
                New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "cs.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $BinDir"
            Expand-Archive -Path $TempZip -DestinationPath $BinDir -Force
            Remove-Item -Force $TempZip

            if (Test-Path (Join-Path $BinDir "cs.exe")) {
                Rename-Item -Path (Join-Path $BinDir "cs.exe") -NewName "coursier.exe"
            }

            Set-LibscriptAlias -Component "coursier" -AliasName $CoursierVersion -ExactVersion $ExactVersion
        }
        break
    }
}
