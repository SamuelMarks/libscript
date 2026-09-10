@echo off
:: ## Overview
:: Windows setup for QEMU
::
:: ## Usage
:: Managed by libscript. Installs QEMU on Windows via winget or choco.
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="install" (
    where qemu-system-x86_64 >nul 2>&1
    if !errorlevel! equ 0 (
        echo QEMU is already installed.
        exit /b 0
    )
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        winget install --silent --force --id=SoftwareFreedomConservancy.QEMU -e --accept-package-agreements --accept-source-agreements
        exit /b !errorlevel!
    )
    where choco >nul 2>&1
    if !errorlevel! equ 0 (
        choco install -y qemu
        exit /b !errorlevel!
    )
    echo Neither winget nor choco found to install QEMU.
    exit /b 1
)
exit /b 0
