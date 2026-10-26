@echo off
setlocal EnableDelayedExpansion
:: # setup_windows.cmd
::
:: ## Overview
:: Setup script for Hetzner CLI on Windows.
:: Installs official Hetzner Cloud CLI (hcloud) via winget.
::
:: ## Usage
:: Automatically invoked during libscript hetzner installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

where hcloud >nul 2>&1
if %errorlevel% equ 0 exit /b 0

echo Installing Hetzner Cloud CLI via pkg_mgr...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_depends HetznerCloud.CLI

where hcloud >nul 2>&1
if %errorlevel% equ 0 exit /b 0

for /d %%W in ("%LOCALAPPDATA%\Microsoft\WinGet\Packages\HetznerCloud.CLI*") do (
    if exist "%%W\hcloud.exe" (
        set "DEST_DIR=%USERPROFILE%\.libscript\hetzner\latest\bin"
        if not exist "!DEST_DIR!" mkdir "!DEST_DIR!"
        copy /y "%%W\hcloud.exe" "!DEST_DIR!\hcloud.exe" >nul 2>&1
        if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
        copy /y "%%W\hcloud.exe" "%USERPROFILE%\.local\bin\hcloud.exe" >nul 2>&1
        exit /b 0
    )
)

exit /b 0
