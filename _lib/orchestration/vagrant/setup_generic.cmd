@echo off
:: ## Overview
:: Windows setup for HashiCorp Vagrant
set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="install" (
    where vagrant >nul 2>&1
    if !errorlevel! equ 0 (
        echo Vagrant is already installed.
        exit /b 0
    )
    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        winget install --silent --force --id=Hashicorp.Vagrant -e --accept-package-agreements --accept-source-agreements
        exit /b !errorlevel!
    )
    where choco >nul 2>&1
    if !errorlevel! equ 0 (
        choco install -y vagrant
        exit /b !errorlevel!
    )
    echo Neither winget nor choco found to install Vagrant.
    exit /b 1
)
exit /b 0
