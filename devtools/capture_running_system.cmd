@echo off
:: # capture_running_system.cmd
::
:: ## Overview
:: Generic schema-driven "screenshot-to-running-system" engine for Windows.
:: Reads declarative metadata strictly from <target_dir>\packaging.json (or synthesizes
:: defaults from <target_dir>\manifest.json), steps through .msi GUI wizard stages (01..10)
:: via SamuelMarks/msi-rs msi-gui (cropped to 495x392), and captures post-install desktop and
:: browser verification views (10b..14, both unauthenticated login screens and authenticated
:: administrative dashboards) across Windows, Linux, macOS, FreeBSD, and illumos (OmniOS).
::
:: ## Usage
:: devtools\capture_running_system.cmd [--target <dir_or_name|all>] [--os <windows|linux|macos|freebsd|illumos|all>] [--variant <online|offline|both>] [--flow <quick|custom|both>] [--mode <all|wizard|post-install>] [--live-vagrant] [--out-dir <path>]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help

where sh.exe >nul 2>&1
if not errorlevel 1 (
    sh.exe "!SCRIPT_DIR!\capture_running_system.sh" %*
    exit /b !ERRORLEVEL!
)

echo [ERROR] POSIX sh is required to run capture_running_system. >&2
exit /b 1

:: ## show_help
:: Displays command-line usage instructions for capture_running_system.cmd.
:show_help
echo Usage: %~nx0 [--target ^<dir_or_name^|all^>] [--os ^<windows^|linux^|macos^|freebsd^|illumos^|all^>] [--variant ^<online^|offline^|both^>] [--flow ^<quick^|custom^|both^>] [--mode ^<all^|wizard^|post-install^>] [--live-vagrant] [--out-dir ^<path^>]
echo Captures schema-driven .msi wizard and post-install browser verification screenshots.
exit /b 0
