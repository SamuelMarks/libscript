@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for aqua on Windows.
:: Prepares and configures aqua on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript aqua installation on Windows.

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

where aqua >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "ARCH=amd64"
if "%PROCESSOR_ARCHITECTURE%"=="ARM64" set "ARCH=arm64"

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://github.com/aquaproj/aqua/releases/download/v2.62.3/aqua_windows_%ARCH%.zip"
set "TEMP_ZIP=%TEMP%\aqua.zip"

echo Downloading aqua (%ARCH%) from %URL%...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%URL%" "%TEMP_ZIP%"
if errorlevel 1 (
    echo Failed to download aqua.
    exit /b 1
)

tar -xf "%TEMP_ZIP%" -C "%DEST_DIR%"
del "%TEMP_ZIP%" >nul 2>&1

if exist "%DEST_DIR%\aqua.exe" (
    echo aqua installed successfully to %DEST_DIR%.
    exit /b 0
)

exit /b 1
