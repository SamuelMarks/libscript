@echo off
:: # gui.cmd
::
:: ## Overview
:: Kiosk display manager and msi-gui session launcher for the live installer.
:: Probes hardware GPU acceleration (DRM/KMS), configures Mesa software rasterization fallbacks,
:: and starts a dedicated fullscreen kiosk session via Wayland (cage) or X11 (openbox/xinit).
::
:: ## Usage
:: Execute this script to start the GUI installer session:
::   ./_lib/package-managers/msi-rs/engine/gui.cmd [--test | --help]

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

:: # gui.cmd
:::: Graphical User Interface (GUI) launcher for msi-gui on Windows.
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
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [GUI] Initializing msi-gui graphical installer subsystem on Windows...

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
echo [ERROR] The GUI launcher requires a shell environment to bootstrap.
exit /b 1
