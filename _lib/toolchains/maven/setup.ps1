<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'maven' stack.

.DESCRIPTION
Execute this script to install and configure maven on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:MAVEN_INSTALL_METHOD
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

$MavenVersion = $env:MAVEN_VERSION
if ([string]::IsNullOrEmpty($MavenVersion)) {
    $MavenVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($MavenVersion -eq "latest") {
        return "3.9.6"
    }
    return $MavenVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls maven
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
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
        if ($InstallMethod -eq "mise") {
            mise ls-remote maven
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-WebRequest -Uri "https://archive.apache.org/dist/maven/maven-3/"
            $Resp.Content -split "`n" | Where-Object { $_ -match 'href="(\d+\.\d+\.\d+)/"' } | ForEach-Object { $matches[1] }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "maven@${MavenVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "maven" -AliasName $MavenVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=Apache.Maven -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y maven
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "maven@${MavenVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
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
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

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
