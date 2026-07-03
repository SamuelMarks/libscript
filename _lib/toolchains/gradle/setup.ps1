<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'gradle' stack.

.DESCRIPTION
Execute this script to install and configure gradle on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:GRADLE_INSTALL_METHOD
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

$GradleVersion = $env:GRADLE_VERSION
if ([string]::IsNullOrEmpty($GradleVersion)) {
    $GradleVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($GradleVersion -eq "latest") {
        try {
            $Resp = Invoke-RestMethod -Uri "https://services.gradle.org/versions/current"
            $ExactVersion = $Resp.version
        } catch {
            $ExactVersion = "8.7"
        }
    } else {
        $ExactVersion = $GradleVersion
    }
    
    return @{ ExactVersion = $ExactVersion }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls gradle
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            gradle --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $GradleDir = Join-Path $LibscriptHome "gradle"
            if (Test-Path $GradleDir) {
                Get-ChildItem -Path $GradleDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote gradle
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://services.gradle.org/versions/all"
            $Resp | Select-Object -First 30 | ForEach-Object { $_.version }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "gradle@${GradleVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "gradle" -AliasName $GradleVersion -ExactVersion $Info.ExactVersion
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
                winget install --silent --force --id=Gradle.Gradle -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y gradle
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "gradle@${GradleVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion

            $GradleDir = Get-LibscriptVersionDir -Component "gradle" -Version $ExactVersion
            $GradleExe = Join-Path $GradleDir "bin\gradle.bat"

            if (Test-Path $GradleExe) {
                $InstalledVersion = & $GradleExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Gradle $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "gradle" -AliasName $GradleVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $DownloadUrl = "https://services.gradle.org/distributions/gradle-${ExactVersion}-bin.zip"

            if (-not (Test-Path $GradleDir)) {
                New-Item -ItemType Directory -Force -Path $GradleDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "gradle-${ExactVersion}.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $GradleDir"
            Expand-Archive -Path $TempZip -DestinationPath $GradleDir -Force
            Move-Item -Path "$GradleDir\gradle-${ExactVersion}\*" -Destination $GradleDir -Force
            Remove-Item -Recurse -Force "$GradleDir\gradle-${ExactVersion}"
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "gradle" -AliasName $GradleVersion -ExactVersion $ExactVersion
        }
        break
    }
}
