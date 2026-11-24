@echo off
:: # cli.cmd
::
:: ## Overview
:: CLI router for idempotent multicloud VM/distro/unikernel image import on Windows across AWS, Azure, and GCP.
::
:: ## Usage
:: cli.cmd <aws|azure|gcp|distro|register|test> [options...]

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

set "SUB=%~1"
if /i "!SUB!"=="image-import" ( shift & set "SUB=%~1" )
if "!SUB!"=="" goto :show_help
if /i "!SUB!"=="--help" goto :show_help
if /i "!SUB!"=="-h" goto :show_help
if /i "!SUB!"=="aws" ( shift & call "!SCRIPT_DIR!\aws_import.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "!SUB!"=="azure" ( shift & call "!SCRIPT_DIR!\azure_import.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "!SUB!"=="gcp" ( shift & call "!SCRIPT_DIR!\gcp_import.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "!SUB!"=="distro" ( shift & call "!SCRIPT_DIR!\distro_import.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "!SUB!"=="register" ( shift & call "!SCRIPT_DIR!\distro_import.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "!SUB!"=="multicloud" ( shift & call "!SCRIPT_DIR!\distro_import.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
if /i "!SUB!"=="test" ( shift & call "!SCRIPT_DIR!\test.cmd" %1 %2 %3 %4 %5 %6 %7 %8 %9 & exit /b !errorlevel! )
echo [ERROR] Unsupported image-import action: !SUB! >&2
exit /b 1

:: ## show_help
:: Displays CLI help for image-import.
:show_help
echo Usage: cli.cmd ^<aws^|azure^|gcp^|distro^|register^|test^> [--disk=^<path^> ^| --distro=^<target^> --profile=^<preset^>] [--name=^<image_name^>] [--dry-run]
exit /b 0
