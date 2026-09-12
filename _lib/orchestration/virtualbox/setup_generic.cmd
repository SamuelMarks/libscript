@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic setup and installation script for VirtualBox on Windows.
::
:: ## Usage
:: Call this script to install VirtualBox on Windows.

set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="install" (
    where VBoxManage >nul 2>&1
    if !errorlevel! neq 0 (
        where winget >nul 2>&1
        if !errorlevel! equ 0 (
            winget install --silent --force --id=Oracle.VirtualBox -e --accept-package-agreements --accept-source-agreements
        ) else (
            where choco >nul 2>&1
            if !errorlevel! equ 0 (
                choco install -y virtualbox
            ) else (
                echo Neither winget nor choco found to install VirtualBox.
                exit /b 1
            )
        )
    ) else (
        echo VirtualBox is already installed.
    )

    where winget >nul 2>&1
    if !errorlevel! equ 0 (
        winget install --silent --force --id=Oracle.VirtualBoxExtensionPack -e --accept-package-agreements --accept-source-agreements 2>nul
    ) else (
        where choco >nul 2>&1
        if !errorlevel! equ 0 (
            choco install -y virtualbox-extensionpack 2>nul
        )
    )
    exit /b 0
)
exit /b 0
