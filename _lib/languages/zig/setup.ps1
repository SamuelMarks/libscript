<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'zig' stack.

.DESCRIPTION
Execute this script to install and configure zig on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:ZIG_INSTALL_METHOD
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

$ZigVersion = $env:ZIG_VERSION
if ([string]::IsNullOrEmpty($ZigVersion)) {
    $ZigVersion = "0.12.0"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($ZigVersion -eq "latest") {
        return "0.12.0"
    }
    return $ZigVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls zig
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            zig version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $ZigDir = Join-Path $LibscriptHome "zig"
            if (Test-Path $ZigDir) {
                Get-ChildItem -Path $ZigDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote zig
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://ziglang.org/download/index.json"
            $Resp.psobject.properties.name | Where-Object { $_ -match "^\d+\.\d+\.\d+$" }
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "zig@${ZigVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "zig" -AliasName $ZigVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=zig.zig -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y zig
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "zig@${ZigVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $ZigDir = Get-LibscriptVersionDir -Component "zig" -Version $ExactVersion
            $ZigExe = Join-Path $ZigDir "zig.exe"

            if (Test-Path $ZigExe) {
                Set-LibscriptAlias -Component "zig" -AliasName $ZigVersion -ExactVersion $ExactVersion
                return
            }

            $Arch = "x86_64"
            if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
                $Arch = "aarch64"
            }

            $ZipName = "zig-windows-$Arch-$ExactVersion.zip"
            $DownloadUrl = "https://ziglang.org/download/$ExactVersion/$ZipName"

            if (-not (Test-Path $ZigDir)) {
                New-Item -ItemType Directory -Force -Path $ZigDir | Out-Null
            }

            $TempZip = Join-Path [System.IO.Path]::GetTempPath() $ZipName
            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempZip

            Write-Host "Extracting $TempZip to $ZigDir"
            Expand-Archive -Path $TempZip -DestinationPath $ZigDir -Force
            # Zig zip extracts a folder named like the zip without .zip
            $NestedDir = Join-Path $ZigDir "zig-windows-$Arch-$ExactVersion"
            if (Test-Path $NestedDir) {
                Move-Item -Path "$NestedDir\*" -Destination $ZigDir -Force
                Remove-Item -Recurse -Force $NestedDir
            }
            Remove-Item -Force $TempZip

            Set-LibscriptAlias -Component "zig" -AliasName $ZigVersion -ExactVersion $ExactVersion
        }
        break
    }
}
