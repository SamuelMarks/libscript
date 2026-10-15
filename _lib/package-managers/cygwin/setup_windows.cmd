@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for cygwin on Windows.
:: Prepares and configures cygwin on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript cygwin installation on Windows.

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

where cygwin >nul 2>&1
if %errorlevel% equ 0 exit /b 0

if exist "C:\cygwin64\bin\bash.exe" exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

echo Downloading Cygwin setup from https://www.cygwin.com/setup-x86_64.exe...
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\pkg_mgr.cmd" :libscript_download "https://www.cygwin.com/setup-x86_64.exe" "%DEST_DIR%\setup-x86_64.exe"
if errorlevel 1 (
    echo Failed to download Cygwin setup.
    exit /b 1
)

echo Cygwin installer downloaded successfully.
exit /b 0
