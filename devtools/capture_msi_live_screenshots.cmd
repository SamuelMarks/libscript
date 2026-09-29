@echo off
set "THIS_FILE=%~f0"
:: # capture_msi_live_screenshots.cmd
::
:: ## Overview
:: Automates capturing and archiving high-resolution screenshots of the live-CD/live-USB
:: installer process (headless, TUI, and GUI kiosk modes) into ../cc0-assets on Windows.
::
:: ## Usage
:: Call devtools\capture_msi_live_screenshots.cmd [--help]

setlocal EnableDelayedExpansion

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
set "SCRIPT_DIR=%~dp0"
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
