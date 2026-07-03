<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'swift' stack.

.DESCRIPTION
Execute this script to install and configure swift on the local system.
#>

#!/usr/bin/env pwsh

$InstallMethod = $env:SWIFT_INSTALL_METHOD
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

$SwiftVersion = $env:SWIFT_VERSION
if ([string]::IsNullOrEmpty($SwiftVersion)) {
    $SwiftVersion = "5.10"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($SwiftVersion -eq "latest") {
        return "5.10"
    }
    return $SwiftVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls swift
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            swift --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $SwiftDir = Join-Path $LibscriptHome "swift"
            if (Test-Path $SwiftDir) {
                Get-ChildItem -Path $SwiftDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote swift
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            Write-Host "5.9.2"
            Write-Host "5.10"
            Write-Host "5.10.1"
            Write-Host "6.0"
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "swift@${SwiftVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "swift" -AliasName $SwiftVersion -ExactVersion $ExactVersion
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
                winget install --silent --force --id=Apple.Swift -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y swift
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "swift@${SwiftVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $SwiftDir = Get-LibscriptVersionDir -Component "swift" -Version $ExactVersion
            $SwiftExe = Join-Path $SwiftDir "usr\bin\swift.exe"

            if (Test-Path $SwiftExe) {
                Set-LibscriptAlias -Component "swift" -AliasName $SwiftVersion -ExactVersion $ExactVersion
                return
            }

            Write-Host "Downloading Swift for Windows natively is currently better handled by Winget."
            Write-Host "Falling back to system winget installation..."
            winget install --silent --force --id=Apple.Swift -e --accept-package-agreements --accept-source-agreements
            
            Set-LibscriptAlias -Component "swift" -AliasName $SwiftVersion -ExactVersion $ExactVersion
        }
        break
    }
}
