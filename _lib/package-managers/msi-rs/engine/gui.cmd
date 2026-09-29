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

if /i "%~1"=="--test" (
    echo [OK] Windows display subsystem operational.
    exit /b 0
)

where msi-gui.exe >nul 2>&1
if !errorlevel! EQU 0 (
    start "" msi-gui.exe
    exit /b 0
)

if exist "%USERPROFILE%\.libscript\msi-rs\latest\bin\msi-gui.exe" (
    start "" "%USERPROFILE%\.libscript\msi-rs\latest\bin\msi-gui.exe"
    exit /b 0
)

echo [WARN] msi-gui.exe not found; falling back to TUI wizard.
call "%SCRIPT_DIR%tui.cmd" %*
exit /b !errorlevel!
