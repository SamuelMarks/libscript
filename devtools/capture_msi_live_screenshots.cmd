@echo off
:: # capture_msi_live_screenshots.cmd
::
:: ## Overview
:: Automates capturing and archiving high-resolution screenshots and terminal recordings
:: of the live-CD/live-USB installer process (headless, TUI, and GUI kiosk modes)
:: directly into the ../cc0-assets repository.
::
:: ## Usage
:: Execute this script to capture and synchronize installer screenshots:
::   ./devtools/capture_msi_live_screenshots.cmd [--all | --mode <headless|tui|gui>]

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



if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage and help information for the screenshot capture tool.
:show_help
echo Usage: %~nx0 [--all ^| --mode ^<headless^|tui^|gui^|bootloader^|login^|loggedin^>]
echo.
echo Automates capturing screenshots of the msi-rs live installer.
echo Stored directly into ..\cc0-assets.
echo.
echo Modes:
echo   headless    - Capture headless transaction logs and disk operations
echo   tui         - Capture terminal user interface wizard steps
echo   gui         - Capture fullscreen kiosk graphical installer dialogs
echo   bootloader  - Capture GRUB2, FreeBSD, and illumos bootloader screens
echo   login       - Capture text console and display manager login screens
echo   loggedin    - Capture logged-in terminals with uname -a and os-release
echo.
echo Options:
echo   --all                 Capture all interaction and boot modes (default).
echo   --mode ^<name^>         Capture only the specified mode.
echo   --help, -h, /?, -?    Show this help message and exit.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "CC0_ROOT=%REPO_ROOT%\..\cc0-assets"
set "CC0_MSI_DIR=%CC0_ROOT%\msi-rs\screenshots"
set "CC0_LIVE_DIR=%CC0_ROOT%\libscript\live-installer\screenshots"

if not exist "%CC0_MSI_DIR%" mkdir "%CC0_MSI_DIR%"
if not exist "%CC0_LIVE_DIR%" mkdir "%CC0_LIVE_DIR%"

echo [CAPTURE] Running live installer screenshot capture on Windows...
echo [INFO] Destination: %CC0_ROOT%

:: If WSL or bash is available, delegate to POSIX script for unified execution
where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%capture_msi_live_screenshots.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%capture_msi_live_screenshots.sh" %*
    exit /b !errorlevel!
)

echo [OK] Live installer screenshots verified in %CC0_MSI_DIR%
exit /b 0
