@echo off
:: ## Overview
:: Windows setup for Bento Builder stack.
::
:: ## Usage
:: Internal generic setup script for Bento Builder on Windows.

set "THIS_FILE=%~f0"

if "%ACTION%"=="" set ACTION=install

if "%ACTION%"=="install" (
    echo Provisioning Bento Builder environment on Windows...
    call "%~dp0\..\..\..\_lib\orchestration\qemu\setup.cmd" install
    call "%~dp0\..\..\..\_lib\orchestration\virtualbox\setup.cmd" install
    call "%~dp0\..\..\..\_lib\orchestration\packer\setup.cmd" install
    call "%~dp0\..\..\..\_lib\orchestration\vagrant\setup.cmd" install

    where 7z >nul 2>&1
    if !errorlevel! neq 0 (
        winget install --silent --force --id=7zip.7zip -e --accept-package-agreements --accept-source-agreements 2>nul
    )
    where git >nul 2>&1
    if !errorlevel! neq 0 (
        winget install --silent --force --id=Git.Git -e --accept-package-agreements --accept-source-agreements 2>nul
    )
    echo Bento Builder environment provisioned on Windows.
)
exit /b 0
