@echo off
:: ## Overview
:: Windows setup for Bento Builder stack.
::
:: ## Usage
:: Internal generic setup script for Bento Builder on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

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
