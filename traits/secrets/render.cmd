@echo off
:: # render.cmd
::
:: ## Overview
:: Delegates safe template rendering to _lib\_common\envsubst_safe.cmd and find_replace.cmd on Windows.
::
:: ## Usage
:: traits\secrets\render.cmd <template_file> <output_file> [secrets_kv_file]

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "TPL_FILE=%~1"
set "OUT_FILE=%~2"
set "SECRETS_FILE=%~3"
if "%TPL_FILE%"=="" goto :help_err
if "%OUT_FILE%"=="" goto :help_err

call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\envsubst_safe.cmd" "%TPL_FILE%" "%OUT_FILE%"
exit /b %errorlevel%

:: ## help
:: Prints usage help for render.cmd.
:help
echo Usage: render.cmd ^<template_file^> ^<output_file^> [secrets_kv_file]
exit /b 0

:: ## help_err
:: Prints usage help and exits with code 1.
:help_err
echo Usage: render.cmd ^<template_file^> ^<output_file^> [secrets_kv_file] 1>&2
exit /b 1
