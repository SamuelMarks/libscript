<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'csharp' stack.

.DESCRIPTION
Execute this script to install and configure csharp on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:CSHARP_INSTALL_METHOD
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

$CsharpVersion = $env:CSHARP_VERSION
if ([string]::IsNullOrEmpty($CsharpVersion)) {
    $CsharpVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-CsharpChannel {
    if ($CsharpVersion -eq "latest") {
        return "LTS"
    }
    return $CsharpVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls dotnet
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            dotnet --list-sdks
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $CsharpDir = Join-Path $LibscriptHome "csharp"
            if (Test-Path $CsharpDir) {
                Get-ChildItem -Path $CsharpDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote dotnet
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            Write-Host "8.0"
            Write-Host "9.0"
            Write-Host "LTS"
            Write-Host "STS"
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "dotnet@${CsharpVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Channel = Resolve-CsharpChannel
            Set-LibscriptAlias -Component "csharp" -AliasName $CsharpVersion -ExactVersion $Channel
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
                winget install --silent --force --id=Microsoft.DotNet.SDK.8 -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y Microsoft.DotNet.SDK.8
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "dotnet@${CsharpVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Channel = Resolve-CsharpChannel
            $CsharpDir = Get-LibscriptVersionDir -Component "csharp" -Version $Channel
            $DotnetExe = Join-Path $CsharpDir "dotnet.exe"

            if (Test-Path $DotnetExe) {
                Set-LibscriptAlias -Component "csharp" -AliasName $CsharpVersion -ExactVersion $Channel
                return
            }

            if (-not (Test-Path $CsharpDir)) {
                New-Item -ItemType Directory -Force -Path $CsharpDir | Out-Null
            }

            $InstallPs1 = Join-Path [System.IO.Path]::GetTempPath() "dotnet-install.ps1"
            Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $InstallPs1

            & pwsh -NoProfile -ExecutionPolicy unrestricted -Command $InstallPs1 -Channel $Channel -InstallDir $CsharpDir

            Remove-Item -Force $InstallPs1

            Set-LibscriptAlias -Component "csharp" -AliasName $CsharpVersion -ExactVersion $Channel
        }
        break
    }
}
