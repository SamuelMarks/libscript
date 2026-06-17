$ErrorActionPreference = "Stop"

#!/usr/bin/env pwsh

$InstallMethod = $env:PYTHON_INSTALL_METHOD
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = $env:LIBSCRIPT_GLOBAL_INSTALL_METHOD
}
if ([string]::IsNullOrEmpty($InstallMethod)) {
    $InstallMethod = "system"
}

$WinPkgMgr = $env:LIBSCRIPT_WINDOWS_PKG_MGR
if ([string]::IsNullOrEmpty($WinPkgMgr)) {
    $WinPkgMgr = "winget"
}

if ($InstallMethod -eq "system" -and $WinPkgMgr -eq "winget") {
    winget install --silent --force --id=Python.Python.3.11 -e --accept-package-agreements --accept-source-agreements
} elseif ($InstallMethod -eq "system" -and $WinPkgMgr -eq "choco") {
    choco install -y python311
} else {
    powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"
    uv python install "3.11"
}

$ML_ACCELERATOR = $env:ML_ACCELERATOR_BACKEND
if (![string]::IsNullOrEmpty($ML_ACCELERATOR)) {
    Write-Host "Installing hardware-optimized ML profile: $ML_ACCELERATOR"
    if ($ML_ACCELERATOR -eq "gpu-cuda12") {
        python -m pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
    } elseif ($ML_ACCELERATOR -eq "gpu-jax") {
        python -m pip install "jax[cuda12]"
    } else {
        Write-Host "Unknown or unsupported ML_ACCELERATOR_BACKEND on Windows: $ML_ACCELERATOR. Skipping."
    }
}

if (Test-Path "requirements.txt") {
    python -m pip install -r requirements.txt
}
if ((Test-Path "setup.py") -or (Test-Path "setup.cfg") -or (Test-Path "pyproject.toml")) {
    python -m pip install -e .
}
