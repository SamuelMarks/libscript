@echo off
setlocal EnableDelayedExpansion
:: # packaging/hydrate_offline_cache.cmd
::
:: ## Overview
:: Windows Batch driver for hydrating and verifying the offline air-gapped
:: artifact cache for LibScript installers.
::
:: ## Usage
:: call packaging\hydrate_offline_cache.cmd [OPTIONS]
::
:: Options:
::   --manifest <path>     Path to offline_bundle.json manifest
::   --cache-dir <dir>     Target cache staging directory
::   --verify-only         Verify SHA-256 integrity without downloading
::   --wheels              Trigger Python wheels downloading
::   --codebase            Fetch core codebase archive
::   --help, -h            Show this help text

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

for %%I in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "MANIFEST="
set "CACHE_DIR="
set "COMPONENT="
set "VERIFY_ONLY="
set "WHEELS="
set "CODEBASE="

:parse_loop
if "%~1"=="" goto :execute
if /i "%~1"=="--manifest" (
    set "MANIFEST=%~2"
    shift & shift
    goto :parse_loop
)
if /i "%~1"=="--cache-dir" (
    set "CACHE_DIR=%~2"
    shift & shift
    goto :parse_loop
)
if /i "%~1"=="--component" (
    set "COMPONENT=%~2"
    shift & shift
    goto :parse_loop
)
if /i "%~1"=="--verify-only" (
    set "VERIFY_ONLY=1"
    shift
    goto :parse_loop
)
if /i "%~1"=="--wheels" (
    set "WHEELS=1"
    shift
    goto :parse_loop
)
if /i "%~1"=="--codebase" (
    set "CODEBASE=1"
    shift
    goto :parse_loop
)
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help

echo Error: Unknown option "%~1" >&2
exit /b 1

:show_help
echo Usage: %~nx0 [OPTIONS]
echo.
echo Options:
echo   --manifest ^<path^>     Path to offline_bundle.json manifest
echo   --cache-dir ^<dir^>     Target cache staging directory
echo   --component ^<name^>    Filter by component (mysql, redis, mongodb, python, nodejs, meilisearch, codebase, wheels, all)
echo   --verify-only         Verify SHA-256 integrity without downloading
echo   --wheels              Trigger Python wheels downloading
echo   --codebase            Fetch core codebase archive
echo   --help, -h            Show this help text
exit /b 0

:execute
set "PS_ARGS="
if not "%MANIFEST%"=="" set PS_ARGS=!PS_ARGS! -Manifest "%MANIFEST%"
if not "%CACHE_DIR%"=="" set PS_ARGS=!PS_ARGS! -CacheDir "%CACHE_DIR%"
if not "%COMPONENT%"=="" set PS_ARGS=!PS_ARGS! -Component "%COMPONENT%"
if "%VERIFY_ONLY%"=="1" set PS_ARGS=!PS_ARGS! -VerifyOnly
if "%WHEELS%"=="1" set PS_ARGS=!PS_ARGS! -Wheels
if "%CODEBASE%"=="1" set PS_ARGS=!PS_ARGS! -Codebase

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\hydrate_offline_cache.ps1" !PS_ARGS!
exit /b %errorlevel%
