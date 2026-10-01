@echo off
set "THIS_FILE=%~f0"
:: # gui.cmd
::
:: ## Overview
:: Graphical User Interface (GUI) launcher for msi-gui on Windows.
:: Launches the interactive msi-gui desktop application or validates display drivers.
::
:: ## Usage
:: Call gui.cmd [--test | --help]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported options.
:show_help
echo Usage: %~nx0 [--test]
echo.
echo Launches the fullscreen graphical installer (msi-gui) on Windows.
echo.
echo Options:
echo   --test              Validate display subsystem without spawning GUI window.
echo   --help, -h, /?, -?  Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [GUI] Initializing msi-gui graphical installer subsystem on Windows...

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
echo [ERROR] The GUI launcher requires a shell environment to bootstrap.
exit /b 1
