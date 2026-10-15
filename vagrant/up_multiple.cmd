@echo off
setlocal EnableDelayedExpansion

:: # up_multiple.cmd
::
:: ## Overview
:: Vagrant environment configuration and setup scripts for multiple nodes.
:: 
:: ## Usage
:: Execute this script within the context of Vagrant provisioning.
:: Define VAGRANT_IMAGE_DIR and VAGRANT_N environment variables.
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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
:: ## show_help
:: Displays command-line usage instructions and available options.
echo Usage: %~nx0
echo Vagrant environment configuration and setup scripts.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes the primary orchestration workflow for this script.
:main
:: ## main
:: Executes the primary orchestration workflow for this script.
set "DIR=%~dp0"
:: Remove trailing backslash if present
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

if not defined VAGRANT_IMAGE_DIR set "VAGRANT_IMAGE_DIR=k8s-thw-debian"
if not defined VAGRANT_N set "VAGRANT_N=3"

pushd "%DIR%\%VAGRANT_IMAGE_DIR%" || (
    echo Failed to change directory to "%DIR%\%VAGRANT_IMAGE_DIR%"
    exit /b 1
)

set /a "max_index=%VAGRANT_N% - 1"
for /L %%i in (0, 1, %max_index%) do (
    vagrant up "%VAGRANT_IMAGE_DIR%%%i"
)

popd
exit /b 0
