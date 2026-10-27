@echo off
:: # capture_msi_vagrant_matrix.cmd
::
:: ## Overview
:: Automates stepping through every stage of .msi GUI installers built with SamuelMarks/msi-rs
:: and capturing post-install desktop and browser verification views across Windows, Linux,
:: macOS, FreeBSD, and illumos (OmniOS) by delegating to the schema-driven
:: devtools\capture_running_system.cmd engine.
::
:: ## Usage
:: devtools\capture_msi_vagrant_matrix.cmd [--target <name|dir|all>] [--os <windows|linux|macos|freebsd|illumos|all>] [--variant <online|offline|both>] [--flow <quick|custom|both>] [--out-dir <path>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

call "!SCRIPT_DIR!\capture_running_system.cmd" %*
exit /b !ERRORLEVEL!

:: ## show_help
:: Displays command-line usage instructions for capture_msi_vagrant_matrix.cmd.
:show_help
call "!SCRIPT_DIR!\capture_running_system.cmd" --help
exit /b 0
