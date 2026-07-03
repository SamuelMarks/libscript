<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'sbt' stack.

.DESCRIPTION
Execute this script to install and configure sbt on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:SBT_INSTALL_METHOD
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

$SbtVersion = $env:SBT_VERSION
if ([string]::IsNullOrEmpty($SbtVersion)) {
    $SbtVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($SbtVersion -eq "latest") {
        try {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/sbt/sbt/releases/latest"
            $ExactVersion = $Resp.tag_name.TrimStart('v')
        } catch {
            $ExactVersion = "1.9.9"
        }
    } else {
        $ExactVersion = $SbtVersion
    }
    
    return @{ ExactVersion = $ExactVersion }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls sbt
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            sbt --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $SbtDir = Join-Path $LibscriptHome "sbt"
            if (Test-Path $SbtDir) {
                Get-ChildItem -Path $SbtDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote sbt
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/sbt/sbt/releases"
            $Resp | Select-Object -First 30 | ForEach-Object { $_.tag_name.TrimStart('v') }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "sbt@${SbtVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "sbt" -AliasName $SbtVersion -ExactVersion $Info.ExactVersion
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
                winget install --silent --force --id=Scala.sbt -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y sbt
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "sbt@${SbtVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion

            $SbtDir = Get-LibscriptVersionDir -Component "sbt" -Version $ExactVersion
            $SbtExe = Join-Path $SbtDir "bin\sbt.bat"

            if (Test-Path $SbtExe) {
                $InstalledVersion = & $SbtExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Sbt $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "sbt" -AliasName $SbtVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $DownloadUrl = "https://github.com/sbt/sbt/releases/download/v$ExactVersion/sbt-$ExactVersion.zip"

            if (-not (Test-Path $SbtDir)) {
                New-Item -ItemType Directory -Force -Path $SbtDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "sbt-${ExactVersion}.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $SbtDir"
            Expand-Archive -Path $TempZip -DestinationPath $SbtDir -Force
            Move-Item -Path "$SbtDir\sbt\*" -Destination $SbtDir -Force
            Remove-Item -Recurse -Force "$SbtDir\sbt"
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "sbt" -AliasName $SbtVersion -ExactVersion $ExactVersion
        }
        break
    }
}
