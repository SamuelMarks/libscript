@echo off
:: # paths.cmd
::
:: ## Overview
:: Filesystem path resolution and canonicalization utilities for LibScript.
::
:: ## Usage
:: Call this script to resolve DOWNLOAD_DIR, DATA_DIR, BIN_DIR, and LOGS_DIR for a component.

set "THIS_FILE=%~f0"

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
