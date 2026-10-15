@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for cargo-binstall on Windows.
:: Prepares and configures cargo-binstall on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript cargo-binstall installation on Windows.

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

where cargo-binstall >nul 2>&1
if %errorlevel% equ 0 (
    echo cargo-binstall is already installed.
    exit /b 0
)

set "ARCH=x86_64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=aarch64"

set "URL=https://github.com/cargo-bins/cargo-binstall/releases/download/v1.23.0/cargo-binstall-%ARCH%-pc-windows-msvc.zip"
set "DEST_DIR=%USERPROFILE%\.cargo\bin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "TEMP_ZIP=%TEMP%\cargo-binstall.zip"
echo Downloading cargo-binstall (%ARCH%) from %URL%...
curl -sSL "%URL%" -o "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download cargo-binstall.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\cargo-binstall.exe" (
    echo cargo-binstall installed successfully.
    exit /b 0
)

echo Failed to install cargo-binstall.
exit /b 1
