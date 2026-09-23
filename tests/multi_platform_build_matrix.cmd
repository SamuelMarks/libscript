@echo off
setlocal EnableDelayedExpansion
:: # multi_platform_build_matrix.cmd
::
:: ## Overview
:: Validates multi-platform host synthesis capabilities on Windows, verifying
:: profiles and script integrity across the target matrix.
::
:: ## Usage
:: call tests\multi_platform_build_matrix.cmd

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
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo [MATRIX] Starting Multi-Platform Host Build Matrix Verification on Windows...

echo [MATRIX] Checking Glibc Linux target validation...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" config os --validate="%LIBSCRIPT_ROOT_DIR%\profiles\linux-standard-server-glibc.json"

echo [MATRIX] Checking Musl Linux target validation...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" config os --validate="%LIBSCRIPT_ROOT_DIR%\profiles\linux-minimal-headless-musl.json"

echo [MATRIX] Checking FreeBSD target validation...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" config os --validate="%LIBSCRIPT_ROOT_DIR%\profiles\freebsd-server-standard.json"

echo [MATRIX] Checking Unikernel target validation...
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" config os --validate="%LIBSCRIPT_ROOT_DIR%\profiles\unikraft-nginx-redis.json"

echo [OK] Multi-platform host build matrix verification passed successfully on Windows.
exit /b 0
