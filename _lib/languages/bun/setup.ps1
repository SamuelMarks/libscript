<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'bun' stack.

.DESCRIPTION
Execute this script to install and configure bun on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:BUN_INSTALL_METHOD
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

$BunVersion = $env:BUN_VERSION
if ([string]::IsNullOrEmpty($BunVersion)) {
    $BunVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($BunVersion -eq "latest") {
        try {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/oven-sh/bun/releases/latest"
            $ExactVersion = $Resp.tag_name.TrimStart('v')
        } catch {
            $ExactVersion = "1.1.20"
        }
    } elseif ($BunVersion -eq "canary") {
        $ExactVersion = "canary"
    } else {
        $ExactVersion = $BunVersion.TrimStart('v')
    }
    
    $Arch = "x64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $Arch = "aarch64"
    }

    return @{ ExactVersion = $ExactVersion; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls bun
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            bun --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $BunDir = Join-Path $LibscriptHome "bun"
            if (Test-Path $BunDir) {
                Get-ChildItem -Path $BunDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote bun
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/oven-sh/bun/releases"
            $Resp | Select-Object -First 30 | ForEach-Object { $_.tag_name.TrimStart('v') }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "bun@${BunVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "bun" -AliasName $BunVersion -ExactVersion $Info.ExactVersion
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
                winget install --silent --force --id=Oven.Bun -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y bun
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "bun@${BunVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $Arch = $Info.Arch

            $BunDir = Get-LibscriptVersionDir -Component "bun" -Version $ExactVersion
            $BunExe = Join-Path $BunDir "bin\bun.exe"

            if (Test-Path $BunExe) {
                $InstalledVersion = & $BunExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Bun $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "bun" -AliasName $BunVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $Target = "bun-windows-$Arch"
            if ($ExactVersion -eq "canary") {
                $DownloadUrl = "https://github.com/oven-sh/bun/releases/download/canary/$Target.zip?v=canary"
            } else {
                $DownloadUrl = "https://github.com/oven-sh/bun/releases/download/bun-v$ExactVersion/$Target.zip?v=$ExactVersion"
            }

            $BinDir = Join-Path $BunDir "bin"
            if (-not (Test-Path $BinDir)) {
                New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "$Target.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $BinDir"
            Expand-Archive -Path $TempZip -DestinationPath $BinDir -Force
            Move-Item -Path "$BinDir\$Target\bun.exe" -Destination $BinDir -Force
            Remove-Item -Recurse -Force "$BinDir\$Target"
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "bun" -AliasName $BunVersion -ExactVersion $ExactVersion
        }
        break
    }
}
