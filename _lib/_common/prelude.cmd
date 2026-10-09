@echo off
:: # prelude.cmd
::
:: ## Overview
:: Common preamble and initialization logic shared across scripts.
:: 
:: ## Usage
:: This script is intended to be sourced by other scripts, not executed directly.

setlocal EnableDelayedExpansion

:: Initialize STACK variable
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

set "searchVal=;%THIS_FILE%;"
if not defined STACK (
    set "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) else (
    if not "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%" 1>&2
        exit /b 0
    ) else (
        set "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

IF NOT DEFINED LIBSCRIPT_ROOT_DIR (
    SET "LIBSCRIPT_ROOT_DIR=%~dp0"
)

if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help
if "%~1"=="-?" goto show_help

IF NOT DEFINED LIBSCRIPT_BUILD_DIR (
    SET "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
)
IF NOT DEFINED LIBSCRIPT_DATA_DIR (
    SET "LIBSCRIPT_DATA_DIR=%TEMP%\libscript_data"
)

SET "PATH=%USERPROFILE%\.cargo\bin;%LIBSCRIPT_DATA_DIR%\bin;%PATH%"

IF NOT EXIST "%LIBSCRIPT_BUILD_DIR%" mkdir "%LIBSCRIPT_BUILD_DIR%"
IF NOT EXIST "%LIBSCRIPT_DATA_DIR%" mkdir "%LIBSCRIPT_DATA_DIR%"

exit /b 0

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Usage: %0
exit /b 0
