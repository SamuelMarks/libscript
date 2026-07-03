<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'just' stack.

.DESCRIPTION
Execute this script to install and configure just on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:JUST_INSTALL_METHOD
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

$JustVersion = $env:JUST_VERSION
if ([string]::IsNullOrEmpty($JustVersion)) {
    $JustVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($JustVersion -eq "latest") {
        return "1.39.0"
    }
    return $JustVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls just
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            just --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $JustDir = Join-Path $LibscriptHome "just"
            if (Test-Path $JustDir) {
                Get-ChildItem -Path $JustDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote just
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/casey/just/releases"
            $Resp | ForEach-Object { $_.tag_name.Replace("v", "") } | Select-Object -First 100
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "just@${JustVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "just" -AliasName $JustVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=casey.just -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y just
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "just@${JustVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $JustDir = Get-LibscriptVersionDir -Component "just" -Version $ExactVersion
            $JustExe = Join-Path $JustDir "bin\just.exe"

            if (Test-Path $JustExe) {
                Set-LibscriptAlias -Component "just" -AliasName $JustVersion -ExactVersion $ExactVersion
                return
            }

            $Arch = "x86_64"
            if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
                $Arch = "aarch64"
            }
            $OsName = "pc-windows-msvc"

            $ZipName = "just-$ExactVersion-$Arch-$OsName.zip"
            $DownloadUrl = "https://github.com/casey/just/releases/download/$ExactVersion/$ZipName"

            $BinDir = Join-Path $JustDir "bin"
            if (-not (Test-Path $BinDir)) {
                New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "just.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $BinDir"
            Expand-Archive -Path $TempZip -DestinationPath $BinDir -Force
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "just" -AliasName $JustVersion -ExactVersion $ExactVersion
        }
        break
    }
}
