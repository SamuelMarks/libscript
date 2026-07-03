<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'bazel' stack.

.DESCRIPTION
Execute this script to install and configure bazel on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:BAZEL_INSTALL_METHOD
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

$BazelVersion = $env:BAZEL_VERSION
if ([string]::IsNullOrEmpty($BazelVersion)) {
    $BazelVersion = "latest"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($BazelVersion -eq "latest") {
        return "v1.25.0"
    }
    return $BazelVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls bazel
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            bazel --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $BazelDir = Join-Path $LibscriptHome "bazel"
            if (Test-Path $BazelDir) {
                Get-ChildItem -Path $BazelDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote bazel
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            $Resp = Invoke-RestMethod -Uri "https://api.github.com/repos/bazelbuild/bazelisk/releases"
            $Resp | ForEach-Object { $_.tag_name.Replace("v", "") } | Select-Object -First 100
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "bazel@${BazelVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "bazel" -AliasName $BazelVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=bazel.bazel -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y bazel
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "bazel@${BazelVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $BazelDir = Get-LibscriptVersionDir -Component "bazel" -Version $ExactVersion
            $BazelExe = Join-Path $BazelDir "bin\bazel.exe"

            if (Test-Path $BazelExe) {
                Set-LibscriptAlias -Component "bazel" -AliasName $BazelVersion -ExactVersion $ExactVersion
                return
            }

            $Arch = "amd64"
            if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
                $Arch = "arm64"
            }

            $DownloadUrl = "https://github.com/bazelbuild/bazelisk/releases/download/$ExactVersion/bazelisk-windows-$Arch.exe"

            $BinDir = Join-Path $BazelDir "bin"
            if (-not (Test-Path $BinDir)) {
                New-Item -ItemType Directory -Force -Path $BinDir | Out-Null
            }

            Write-Host "Downloading $DownloadUrl"
            Invoke-WebRequest -Uri $DownloadUrl -OutFile $BazelExe

            Set-LibscriptAlias -Component "bazel" -AliasName $BazelVersion -ExactVersion $ExactVersion
        }
        break
    }
}
