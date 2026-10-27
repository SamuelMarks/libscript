@echo off
:: # setup.cmd
::
:: ## Overview
:: Orchestrates the setup and installation process for the Celery task queue stack on Windows.
:: Ensures Python with pip is present, installs Celery, and exposes the celery CLI executable.
:: 
:: ## Usage
:: Execute this script to install and configure celery on the local system.

setlocal EnableDelayedExpansion
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

if not defined LIBSCRIPT_ROOT_DIR (
    for %%I in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
)
set "LOG_CMD=!LIBSCRIPT_ROOT_DIR!\_lib\_common\log.cmd"

call "!LOG_CMD!" :log_info "Installing Celery on Windows..."

where python >nul 2>&1
if errorlevel 1 (
    call "!LOG_CMD!" :log_info "Python not found on PATH, attempting installation..."
    if exist "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install python
    )
)

where python >nul 2>&1
if errorlevel 1 (
    call "!LOG_CMD!" :log_error "Python is required to install Celery."
    exit /b 1
)

python -m pip install --quiet --upgrade celery
if errorlevel 1 (
    call "!LOG_CMD!" :log_error "Failed to install Celery via pip."
    exit /b 1
)

set "BIN_DIR=%USERPROFILE%\.libscript\celery\latest\bin"
if not exist "!BIN_DIR!" mkdir "!BIN_DIR!"
(
    echo @echo off
    echo python -m celery %%*
) > "!BIN_DIR!\celery.cmd"

if not exist "%USERPROFILE%\.local\bin" mkdir "%USERPROFILE%\.local\bin"
copy /y "!BIN_DIR!\celery.cmd" "%USERPROFILE%\.local\bin\celery.cmd" >nul 2>&1

call "!LOG_CMD!" :log_info "Celery installed successfully."
exit /b 0
