@echo off
:: # tui.cmd
::
:: ## Overview
:: Terminal User Interface (TUI) installer wizard companion on Windows supporting --test verification and Option A exit 86 for whiptail/dialog live-ISO menus.
::
:: ## Usage
:: synthesis\msi\live_installer\engine\tui.cmd [--test | --help]

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

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if /i "%~1"=="--test" goto :run_test
goto :unsupported_live_tui

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [--test ^| --help]
echo Terminal User Interface wizard for msi-rs live media ^(use msiexec /qb or headless.cmd on Windows^).
exit /b 0

:: ## run_test
:: Runs non-interactive verification of catalog and headless installer integration on Windows.
:run_test
call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\preloader\catalog.cmd" --clean-base >nul
if errorlevel 1 exit /b 1
echo [PASS] Windows TUI preflight verification succeeded.
exit /b 0

:: ## unsupported_live_tui
:: Exits with Option A code 86 when interactive POSIX whiptail/dialog live-ISO console is requested on Windows.
:unsupported_live_tui
echo [UNSUPPORTED] Interactive whiptail/dialog live-ISO TUI requires POSIX live media ^(exit 86^); use msiexec.exe or headless.cmd on Windows. >&2
exit /b 86
