@echo off
:: # paths.cmd
::
:: ## Overview
:: Filesystem path resolution and canonicalization utilities for LibScript.
::
:: ## Usage
:: Call this script to resolve DOWNLOAD_DIR, DATA_DIR, BIN_DIR, and LOGS_DIR for a component.

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

:: ## resolve_component_paths
:: Executes resolve_component_paths functionality.
:resolve_component_paths
if "%PACKAGE_NAME%"=="" (
    for %%I in ("%CD%") do set "PACKAGE_NAME=%%~nxI"
)

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    set "SCRIPT_DIR=%~dp0"
    if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
    for %%I in ("%SCRIPT_DIR%\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
)

if "%LIBSCRIPT_CACHE_DIR%"=="" set "LIBSCRIPT_CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache"
if "%DOWNLOAD_DIR%"=="" set "DOWNLOAD_DIR=%LIBSCRIPT_CACHE_DIR%\downloads\%PACKAGE_NAME%"

if "%LIBSCRIPT_DATA_DIR%"=="" (
    if not "%TEMP%"=="" (
        set "LIBSCRIPT_DATA_DIR=%TEMP%\libscript_data"
    ) else (
        set "LIBSCRIPT_DATA_DIR=%TMP%\libscript_data"
    )
)
if "%DATA_DIR%"=="" set "DATA_DIR=%LIBSCRIPT_DATA_DIR%\%PACKAGE_NAME%"
if "%BIN_DIR%"=="" set "BIN_DIR=%DATA_DIR%\bin"

if "%LIBSCRIPT_LOGS_DIR%"=="" (
    if not "%TEMP%"=="" (
        set "LIBSCRIPT_LOGS_DIR=%TEMP%\libscript_logs"
    ) else (
        set "LIBSCRIPT_LOGS_DIR=%TMP%\libscript_logs"
    )
)
if "%LOGS_DIR%"=="" set "LOGS_DIR=%LIBSCRIPT_LOGS_DIR%\%PACKAGE_NAME%"

if not exist "%DOWNLOAD_DIR%" mkdir "%DOWNLOAD_DIR%" >nul 2>&1
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%" >nul 2>&1
if not exist "%BIN_DIR%" mkdir "%BIN_DIR%" >nul 2>&1
if not exist "%LOGS_DIR%" mkdir "%LOGS_DIR%" >nul 2>&1

exit /b 0
