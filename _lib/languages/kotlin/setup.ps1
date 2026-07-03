<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'kotlin' stack.

.DESCRIPTION
Execute this script to install and configure kotlin on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:KOTLIN_INSTALL_METHOD
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

$KotlinVersion = $env:KOTLIN_VERSION
if ([string]::IsNullOrEmpty($KotlinVersion)) {
    $KotlinVersion = "1.9.20"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($KotlinVersion -eq "latest") {
        return "1.9.20"
    }
    return $KotlinVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls kotlin
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            kotlin -version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $KotlinDir = Join-Path $LibscriptHome "kotlin"
            if (Test-Path $KotlinDir) {
                Get-ChildItem -Path $KotlinDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote kotlin
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/JetBrains/kotlin/releases"
            $Resp | ForEach-Object { $_.tag_name.Replace("v", "") } | Select-Object -First 100
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "kotlin@${KotlinVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "kotlin" -AliasName $KotlinVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=JetBrains.Kotlin -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y kotlin
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "kotlin@${KotlinVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $KotlinDir = Get-LibscriptVersionDir -Component "kotlin" -Version $ExactVersion
            $KotlinExe = Join-Path $KotlinDir "bin\kotlin.bat"

            if (Test-Path $KotlinExe) {
                Set-LibscriptAlias -Component "kotlin" -AliasName $KotlinVersion -ExactVersion $ExactVersion
                return
            }

            $ZipName = "kotlin-compiler-$ExactVersion.zip"
            $DownloadUrl = "https://github.com/JetBrains/kotlin/releases/download/v$ExactVersion/$ZipName"

            if (-not (Test-Path $KotlinDir)) {
                New-Item -ItemType Directory -Force -Path $KotlinDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() $ZipName
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip"
            Expand-Archive -Path $TempZip -DestinationPath $KotlinDir -Force
            # Zip has 'kotlinc' dir inside
            $NestedDir = Join-Path $KotlinDir "kotlinc"
            if (Test-Path $NestedDir) {
                Move-Item -Path "$NestedDir\*" -Destination $KotlinDir -Force
                Remove-Item -Recurse -Force $NestedDir
            }
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "kotlin" -AliasName $KotlinVersion -ExactVersion $ExactVersion
        }
        break
    }
}
