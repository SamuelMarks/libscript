<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'rust' stack.

.DESCRIPTION
Execute this script to install and configure rust on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:RUST_INSTALL_METHOD
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

$RustVersion = $env:RUST_VERSION
if ([string]::IsNullOrEmpty($RustVersion)) {
    $RustVersion = "latest"
}
if ($RustVersion -eq "latest") {
    $RustVersion = "stable"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($RustVersion -eq "stable") {
        try {
            $Resp = Invoke-RestMethod -Uri "https://static.rust-lang.org/dist/channel-rust-stable.toml"
            $Lines = $Resp -split "`n"
            foreach ($Line in $Lines) {
                if ($Line -match "^pkg_version\s*=\s*`"(.+?)`"") {
                    $ExactVersion = ($matches[1] -split ' ')[0]
                    break
                }
            }
        } catch {
            $ExactVersion = "1.77.0"
        }
    } else {
        $ExactVersion = $RustVersion
    }
    return $ExactVersion
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "rustup") {
            rustup toolchain list
        } elseif ($InstallMethod -eq "mise") {
            mise ls rust
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls rust
        } elseif ($InstallMethod -eq "system") {
            rustc --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $RustDir = Join-Path $LibscriptHome "rust"
            if (Test-Path $RustDir) {
                Get-ChildItem -Path $RustDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "rustup") {
            Write-Host "Use rustup to see channels"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            Write-Host "stable`nbeta`nnightly"
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "rustup") {
            rustup default "${RustVersion}"
        } elseif ($InstallMethod -eq "mise") {
            mise use "rust@${RustVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls rust
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $ExactVersion = Resolve-ExactVersion
            Set-LibscriptAlias -Component "rust" -AliasName $RustVersion -ExactVersion $ExactVersion
        }
        break
    }
    
    "start" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_rust" }
        if (Get-Command Libscript-Service -ErrorAction SilentlyContinue) {
            Libscript-Service -Action "start" -ServiceName $ServiceName @args
        } else { Write-Host "start not natively implemented for `$InstallMethod." }
        break
    }
    "install-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_rust" }
        if (Get-Command Libscript-InstallService -ErrorAction SilentlyContinue) {
            Libscript-InstallService -ServiceName $ServiceName @args
        } else { Write-Host "install-service not implemented for `$InstallMethod." }
        break
    }
    "uninstall-service" {
        $ServiceScript = Join-Path $LibscriptRootDir "_lib\_common\service_install.ps1"
        if (Test-Path $ServiceScript) { . $ServiceScript }
        $ServiceName = if ($env:LIBSCRIPT_SERVICE_NAME) { $env:LIBSCRIPT_SERVICE_NAME } else { "libscript_rust" }
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
            Write-Host "Uninstalling rust `$Exact..."
            if (Get-Command Get-LibscriptBaseDir -ErrorAction SilentlyContinue) {
                $LibscriptHome = Get-LibscriptBaseDir
            } else {
                $LibscriptHome = Join-Path $HOME ".libscript"
            }
            $TargetDir = Join-Path $LibscriptHome "rust\`$Exact"
            if (Test-Path $TargetDir) { Remove-Item -Recurse -Force $TargetDir }
        } else {
            Write-Host "Uninstall not implemented or supported for `$InstallMethod."
        }
        break
    }
    "download" {
        if ($InstallMethod -eq "libscript_native") {
            Write-Host "Downloading rust..."
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
                winget install --silent --force --id=Rustlang.Rustup -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y rust
            }
        } elseif ($InstallMethod -eq "rustup") {
            if (-not (Get-Command rustup -ErrorAction SilentlyContinue)) {
                $RustupInit = Join-Path [System.IO.Path]::GetTempPath() "rustup-init.exe"
                Invoke-WebRequest -Uri "https://win.rustup.rs" -OutFile $RustupInit
                Start-Process -FilePath $RustupInit -ArgumentList "-y --default-toolchain $RustVersion" -Wait -NoNewWindow
                Remove-Item -Force $RustupInit
            } else {
                rustup toolchain install $RustVersion
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "rust@${RustVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "pkgx") {
            Write-Host "pkgx not fully supported natively on Windows"
        } elseif ($InstallMethod -eq "vfox") {
            vfox ls rust; exit 1
        } else {
            $ExactVersion = Resolve-ExactVersion
            $RustDir = Get-LibscriptVersionDir -Component "rust" -Version $ExactVersion
            $RustExe = Join-Path $RustDir "bin\rustc.exe"

            if (Test-Path $RustExe) {
                $InstalledVersion = & $RustExe --version
                if ($InstalledVersion -match $ExactVersion) {
                    Write-Host "Rust $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "rust" -AliasName $RustVersion -ExactVersion $ExactVersion
                    return
                }
            }

            if (-not (Test-Path $RustDir)) {
                New-Item -ItemType Directory -Force -Path $RustDir | Out-Null
            }

            # For libscript_native on Windows we'll cheat by using rustup-init but isolating CARGO_HOME and RUSTUP_HOME
            $env:CARGO_HOME = $RustDir
            $env:RUSTUP_HOME = $RustDir
            
            $RustupInit = Join-Path [System.IO.Path]::GetTempPath() "rustup-init.exe"
            Invoke-WebRequest -Uri "https://win.rustup.rs" -OutFile $RustupInit
            Write-Host "Installing Rust natively to $RustDir using rustup-init..."
            Start-Process -FilePath $RustupInit -ArgumentList "-y --no-modify-path --default-toolchain $RustVersion" -Wait -NoNewWindow
            Remove-Item -Force $RustupInit
            
            # The binaries will be in bin
            Set-LibscriptAlias -Component "rust" -AliasName $RustVersion -ExactVersion $ExactVersion
        }
        break
    }
}
