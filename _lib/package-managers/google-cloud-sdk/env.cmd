@echo off
REM ## Overview
REM Environment variable initialization script for the google-cloud-sdk component.
REM It sets up necessary paths and environment variables required for the component
REM to function correctly within the libscript context.
REM 
REM ## Usage
REM Call this script to load the environment variables.
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

if "%LIBSCRIPT_HOME%"=="" (
    set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
)
if "%GOOGLE_CLOUD_SDK_VERSION%"=="" (
    set "GOOGLE_CLOUD_SDK_VERSION=latest"
)

set "_GCLOUD_BIN=%LIBSCRIPT_HOME%\google-cloud-sdk\%GOOGLE_CLOUD_SDK_VERSION%\bin"
echo ;%PATH%; | findstr /I /C:";%_GCLOUD_BIN%;" >nul 2>&1
if errorlevel 1 (
    set "PATH=%_GCLOUD_BIN%;%PATH%"
)

if "%CLOUDSDK_PYTHON%"=="" (
    where python3.12 >nul 2>&1
    if not errorlevel 1 (
        for /f "delims=" %%i in ('where python3.12 2^>nul') do if "%CLOUDSDK_PYTHON%"=="" set "CLOUDSDK_PYTHON=%%i"
    ) else (
        where python3.11 >nul 2>&1
        if not errorlevel 1 (
            for /f "delims=" %%i in ('where python3.11 2^>nul') do if "%CLOUDSDK_PYTHON%"=="" set "CLOUDSDK_PYTHON=%%i"
        )
    )
)
