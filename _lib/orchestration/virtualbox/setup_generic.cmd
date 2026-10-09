@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic setup and installation script for VirtualBox on Windows.
::
:: ## Usage
:: Call this script to install VirtualBox on Windows.

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
