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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "MANIFEST="
set "CACHE_DIR="
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
echo   --verify-only         Verify SHA-256 integrity without downloading
echo   --wheels              Trigger Python wheels downloading
echo   --codebase            Fetch core codebase archive
echo   --help, -h            Show this help text
exit /b 0

:execute
set "PS_ARGS="
if not "%MANIFEST%"=="" set PS_ARGS=!PS_ARGS! -Manifest "%MANIFEST%"
if not "%CACHE_DIR%"=="" set PS_ARGS=!PS_ARGS! -CacheDir "%CACHE_DIR%"
if "%VERIFY_ONLY%"=="1" set PS_ARGS=!PS_ARGS! -VerifyOnly
if "%WHEELS%"=="1" set PS_ARGS=!PS_ARGS! -Wheels
if "%CODEBASE%"=="1" set PS_ARGS=!PS_ARGS! -Codebase

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\hydrate_offline_cache.ps1" !PS_ARGS!
exit /b %errorlevel%
