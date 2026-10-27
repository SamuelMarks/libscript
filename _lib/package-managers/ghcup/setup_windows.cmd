@echo off
:: # setup_windows.cmd
setlocal EnableDelayedExpansion
:: ## Overview
:: Setup script for ghcup on Windows.
:: Prepares and configures ghcup on native Windows environments.
::
:: ## Usage
:: Automatically invoked during libscript ghcup installation on Windows.

set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
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

where ghcup >nul 2>&1
if %errorlevel% equ 0 exit /b 0

set "DEST_DIR=%USERPROFILE%\.local\bin"
if not "%PREFIX%"=="" set "DEST_DIR=%PREFIX%"
if not exist "%DEST_DIR%" mkdir "%DEST_DIR%"

set "URL=https://downloads.haskell.org/~ghcup/x86_64-mingw64-ghcup.exe"

echo Downloading ghcup from %URL%...
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\pkg_mgr.cmd" :libscript_download "%URL%" "%DEST_DIR%\ghcup.exe"
if errorlevel 1 (
    echo Failed to download ghcup.
    exit /b 1
)

if exist "%DEST_DIR%\ghcup.exe" (
    echo ghcup installed successfully.
    exit /b 0
)

exit /b 1
