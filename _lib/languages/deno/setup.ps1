<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'deno' stack.

.DESCRIPTION
Execute this script to install and configure deno on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:DENO_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_DEFAULT_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "libscript_native"
}

$Action = $env:ACTION
if ([string]::IsNullOrEmpty($Action)) {
    $Action = "install"
}

$DenoVersion = $env:DENO_VERSION
if ([string]::IsNullOrEmpty($DenoVersion)) {
    $DenoVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($DenoVersion -eq "latest") {
        try {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/denoland/deno/releases/latest"
            $ExactVersion = $Resp.tag_name.TrimStart('v')
        } catch {
            $ExactVersion = "1.45.2"
        }
    } else {
        $ExactVersion = $DenoVersion.TrimStart('v')
    }
    
    return @{ ExactVersion = $ExactVersion }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls deno
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls deno
        } elseif ($InstallMethod -eq "system") {
            deno --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $DenoDir = Join-Path $LibscriptHome "deno"
            if (Test-Path $DenoDir) {
                Get-ChildItem -Path $DenoDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote deno
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls deno
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/denoland/deno/releases"
            $Resp | Select-Object -First 30 | ForEach-Object { $_.tag_name.TrimStart('v') }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "deno@${DenoVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls deno
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "deno" -AliasName $DenoVersion -ExactVersion $Info.ExactVersion
        }
        break
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_deno" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_deno" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_deno" }
        if (Get-Command Libscript-UninstallService -ErrorAction SilentlyContinue) {
            Libscript-UninstallService -ServiceName $ServiceName @args
        } else { Write-Host "uninstall-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall" {
        if ($InstallMethod -eq "libscript_native") {
            if (Get-Command Resolve-ExactVersion -ErrorAction SilentlyContinue) {
                $Info = Resolve-ExactVersion
                $Exact = $Info.ExactVersion
            } else {
                $Exact = if ($Version) { $Version } else { "latest" }
            }
            Write-Host "Uninstalling deno `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "deno\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading deno..."
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
                winget install --silent --force --id=DenoLand.Deno -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y deno
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "deno@${DenoVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls deno; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion

            $DenoDir = Get-LibscriptVersionDir -Component "deno" -Version $ExactVersion
            $DenoExe = Join-Path $DenoDir "bin\deno.exe"

            if (Test-Path $DenoExe) {
                $InstalledVersion = & $DenoExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Deno $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "deno" -AliasName $DenoVersion -ExactVersion $ExactVersion
                    return
                }
            }

            $Target = "x86_64-pc-windows-msvc"
            $DownloadUrl = "https://github.com/denoland/deno/releases/download/v$ExactVersion/deno-${Target}.zip?v=$ExactVersion"

            $BinDir = Join-Path $DenoDir "bin"
            if (-not (Test-Path $BinDir)) {
                New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() "deno-${Target}.zip"
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $BinDir"
            Expand-Archive -Path $TempZip -DestinationPath $BinDir -Force
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "deno" -AliasName $DenoVersion -ExactVersion $ExactVersion
        }
        break
    }
}
