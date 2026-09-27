@echo off
rem ## Overview
rem Verifies Intel Media Driver staging and installation.
rem
rem ## Usage
rem   call test.cmd

setlocal enabledelayedexpansion

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1 && (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=!STACK!%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    for %%I in ("%SCRIPT_DIR%\..\..\..") do set "REPO_ROOT=%%~fI"
    set "TARGET_SYSROOT=!REPO_ROOT!\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMP_FILE=%TARGET_SYSROOT%\var\lib\libscript\stamps\.stamp.intel-media-driver"
if exist "%STAMP_FILE%" (
    echo [PASS] Intel Media Driver verified via stamp: %STAMP_FILE%
    exit /b 0
)

echo [FAIL] Intel Media Driver not found or not staged.
exit /b 1
