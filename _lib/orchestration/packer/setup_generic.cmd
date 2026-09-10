@echo off
:: ## Overview
:: Windows setup for HashiCorp Packer
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="install" (
    where packer >nul 2>&1
    if !errorlevel! equ 0 (
        echo Packer is already installed.
        exit /b 0
    )
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        winget install --silent --force --id=Hashicorp.Packer -e --accept-package-agreements --accept-source-agreements
        exit /b !errorlevel!
    )
    where choco >nul 2>&1
    if !errorlevel! equ 0 (
        choco install -y packer
        exit /b !errorlevel!
    )
    echo Neither winget nor choco found to install Packer.
    exit /b 1
)
exit /b 0
