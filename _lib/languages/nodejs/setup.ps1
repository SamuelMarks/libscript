<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'nodejs' stack.

.DESCRIPTION
Execute this script to install and configure nodejs on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:NODEJS_INSTALL_METHOD
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

$OriginalNodeVersion = $env:NODEJS_VERSION
if ([string]::IsNullOrEmpty($OriginalNodeVersion)) {
    $OriginalNodeVersion = "lts"
}

$NodeVersion = $OriginalNodeVersion
if ($NodeVersion -eq "lts") {
    $NodeVersion = "22"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    $CleanVersion = $NodeVersion.TrimStart("v")
    $Arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $Arch = "arm64"
    } elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
        $Arch = "x86"
    }

    if (-not $CleanVersion.Contains(".")) {
        if ($CleanVersion -eq "latest") {
            $BaseUrl = "https://nodejs.org/dist/latest"
        } else {
            $BaseUrl = "https://nodejs.org/dist/latest-v${CleanVersion}.x"
        }
        $ShaSums = Invoke-RestMethod -Uri "$BaseUrl/SHASUMS256.txt"
        if ($ShaSums -match "node-v([\d\.]+)-win-$Arch\.zip") {
            $ExactVersion = $matches[1]
        } else {
            $ExactVersion = $CleanVersion
        }
    } else {
        $BaseUrl = "https://nodejs.org/dist/v$CleanVersion"
        $ExactVersion = $CleanVersion
    }
    
    return @{ ExactVersion = $ExactVersion; BaseUrl = $BaseUrl; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls node
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            node -v
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $NodeDir = Join-Path $LibscriptHome "nodejs"
            if (Test-Path $NodeDir) {
                Get-ChildItem -Path $NodeDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote node
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            # Minimal stub
            $Tab = Invoke-RestMethod -Uri "https://nodejs.org/dist/index.tab"
            $Tab -split "`n" | Select-Object -Skip 1 | ForEach-Object { ($_ -split "`t")[0].TrimStart('v') }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "node@${NodeVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "nodejs" -AliasName $OriginalNodeVersion -ExactVersion "v$($Info.ExactVersion)"
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
                winget install --silent --force --id=OpenJS.NodeJS -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y nodejs
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "node@${NodeVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $BaseUrl = $Info.BaseUrl
            $Arch = $Info.Arch

            $NodeDir = Get-LibscriptVersionDir -Component "nodejs" -Version "v$ExactVersion"
            $NodeExe = Join-Path $NodeDir "node.exe"

            if (Test-Path $NodeExe) {
                $InstalledVersion = & $NodeExe --version
                if ($InstalledVersion -like "v${ExactVersion}*") {
                    Write-Host "Node.js $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "nodejs" -AliasName $OriginalNodeVersion -ExactVersion "v$ExactVersion"
                    return
                }
            }

            $ZipName = "node-v$ExactVersion-win-$Arch.zip"
            $DownloadUrl = "$BaseUrl/$ZipName"

            if (-not (Test-Path $NodeDir)) {
                New-Item -ItemType Directory -Force -Path $NodeDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() $ZipName
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $NodeDir"
            Expand-Archive -Path $TempZip -DestinationPath $NodeDir -Force
            $NestedDir = Join-Path $NodeDir "node-v$ExactVersion-win-$Arch"
            Move-Item -Path "$NestedDir\*" -Destination $NodeDir -Force
            Remove-Item -Recurse -Force $NestedDir
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "nodejs" -AliasName $OriginalNodeVersion -ExactVersion "v$ExactVersion"
        }
        break
    }
}
