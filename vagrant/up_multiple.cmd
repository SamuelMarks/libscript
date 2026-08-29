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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Vagrant environment configuration and setup scripts.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:main
:: ## main
:: Executes main functionality.
set "DIR=%~dp0"
:: Remove trailing backslash if present
if "%DIR:~-1%"=="\" set "DIR=%DIR:~0,-1%"

if not defined VAGRANT_IMAGE_DIR set "VAGRANT_IMAGE_DIR=debian12"
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
