<#
.SYNOPSIS
Orchestrates the setup and installation process for the component 'python' stack.

.DESCRIPTION
Execute this script to install and configure python on the local system.
#>

$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:PYTHON_INSTALL_METHOD
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

$PythonVersion = $env:PYTHON_VERSION
if ([string]::IsNullOrEmpty($PythonVersion)) {
    $PythonVersion = "3.11.9"
}

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$LibscriptRootDir = (Get-Item $ScriptDir).Parent.Parent.Parent.FullName
. (Join-Path $LibscriptRootDir "_lib\_common\versioning.ps1")

function Resolve-ExactVersion {
    if ($PythonVersion -eq "latest") {
        # Note: robust HTML parsing omitted for brevity
        $ExactVersion = "3.12.3" 
    } else {
        $ExactVersion = $PythonVersion
    }
    
    $Arch = "amd64"
    if ($env:PROCESSOR_ARCHITECTURE -eq "ARM64") {
        $Arch = "arm64"
    } elseif ($env:PROCESSOR_ARCHITECTURE -eq "x86") {
        $Arch = "win32"
    }

    return @{ ExactVersion = $ExactVersion; Arch = $Arch }
}

switch ($Action) {
    "ls" {
        if ($InstallMethod -eq "mise") {
            mise ls python
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            python --version
        } else {
            $LibscriptHome = Get-LibscriptBaseDir
            $PyDir = Join-Path $LibscriptHome "python"
            if (Test-Path $PyDir) {
                Get-ChildItem -Path $PyDir -Directory | Select-Object -ExpandProperty Name
            }
        }
        break
    }
    "ls-remote" {
        if ($InstallMethod -eq "mise") {
            mise ls-remote python
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "System package manager does not support ls-remote directly here."
        } else {
            Write-Host "Please visit https://www.python.org/downloads/windows/"
        }
        break
    }
    "use" {
        if ($InstallMethod -eq "mise") {
            mise use "python@${PythonVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"
        } elseif ($InstallMethod -eq "system") {
            Write-Host "Cannot 'use' specific version with system package manager."
        } else {
            $Info = Resolve-ExactVersion
            Set-LibscriptAlias -Component "python" -AliasName $PythonVersion -ExactVersion $Info.ExactVersion
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
                winget install --silent --force --id=Python.Python.3.11 -e --accept-package-agreements --accept-source-agreements
            } elseif ($WinPkgMgr -eq "choco") {
                choco install -y python311
            }
        } elseif ($InstallMethod -eq "mise") {
            mise install "python@${PythonVersion}"
        } elseif ($InstallMethod -eq "asdf") {
            Write-Host "asdf not supported natively on Windows"; exit 1
        } else {
            $Info = Resolve-ExactVersion
            $ExactVersion = $Info.ExactVersion
            $Arch = $Info.Arch

            $PyDir = Get-LibscriptVersionDir -Component "python" -Version $ExactVersion
            $PyExe = Join-Path $PyDir "python.exe"

            if (Test-Path $PyExe) {
                $InstalledVersion = & $PyExe --version
                if ($InstalledVersion -match "$ExactVersion") {
                    Write-Host "Python $InstalledVersion is already installed."
                    Set-LibscriptAlias -Component "python" -AliasName $PythonVersion -ExactVersion $ExactVersion
                }
            } else {
                $ExeName = "python-$ExactVersion-$Arch.exe"
                if ($Arch -eq "win32") {
                    $ExeName = "python-$ExactVersion.exe"
                }
                $DownloadUrl = "https://www.python.org/ftp/python/$ExactVersion/$ExeName"

                if (-not (Test-Path $PyDir)) {
                    New-Item -ItemType Directory -Force -Path $PyDir | Out-Null
                }

                $TempExe = Join-Path [System.IO.Path]::GetTempPath() $ExeName
                Write-Host "Downloading $DownloadUrl"
                Invoke-WebRequest -Uri $DownloadUrl -OutFile $TempExe

                Write-Host "Installing $TempExe to $PyDir"
                Start-Process -FilePath $TempExe -ArgumentList "/quiet InstallAllUsers=0 TargetDir=`"$PyDir`" Include_test=0" -Wait -NoNewWindow
                Remove-Item -Force $TempExe

                Set-LibscriptAlias -Component "python" -AliasName $PythonVersion -ExactVersion $ExactVersion
            }

            if (-not [string]::IsNullOrEmpty($env:PYTHON_VENV)) {
                $VenvDir = $env:PYTHON_VENV
                if (-not (Test-Path "$VenvDir\Scripts\python.exe")) {
                    & $PyExe -m venv $VenvDir
                    & "$VenvDir\Scripts\python.exe" -m pip install -U pip setuptools wheel
                    
                    $ML_ACCELERATOR = $env:ML_ACCELERATOR_BACKEND
                    if (![string]::IsNullOrEmpty($ML_ACCELERATOR)) {
                        Write-Host "Installing hardware-optimized ML profile: $ML_ACCELERATOR"
                        if ($ML_ACCELERATOR -eq "gpu-cuda12") {
                            & "$VenvDir\Scripts\python.exe" -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
                        } elseif ($ML_ACCELERATOR -eq "gpu-jax") {
                            & "$VenvDir\Scripts\python.exe" -m pip install "jax[cuda12]"
                        } else {
                            Write-Host "Unknown or unsupported ML_ACCELERATOR_BACKEND on Windows: $ML_ACCELERATOR. Skipping."
                        }
                    }

                    if (Test-Path "requirements.txt") {
                        & "$VenvDir\Scripts\python.exe" -m pip install -r requirements.txt
                    }
                    if ((Test-Path "setup.py") -or (Test-Path "setup.cfg") -or (Test-Path "pyproject.toml")) {
                        & "$VenvDir\Scripts\python.exe" -m pip install -e .
                    }
                }
            }
        }
        break
    }
}
