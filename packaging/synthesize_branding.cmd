@echo off
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

:: # synthesize_branding.cmd
::
:: ## Overview
:: Universal branding synthesizer generating 24-bit BMP banners, multi-resolution ICO,
:: and aggregated RTF EULA for Windows Installer (MSI) packages on Windows.
::
:: ## Usage
::   call packaging\synthesize_branding.cmd <path_to_packaging.json_or_dir> [--output-dir DIR]

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

set "TARGET_SPEC=%~1"
if "%TARGET_SPEC%"=="" (
    echo [ERROR] No stack directory or packaging.json specified >&2
    exit /b 1
)
shift

set "OUTPUT_DIR="
:: ## arg_loop
:: Parses command-line arguments and populates configuration variables.
:arg_loop
if "%~1"=="" goto done_args
if /i "%~1"=="--output-dir" ( set "OUTPUT_DIR=%~2" & shift & shift & goto arg_loop )
if /i "%~1"=="-o" ( set "OUTPUT_DIR=%~2" & shift & shift & goto arg_loop )
set "OUTPUT_DIR=%~1"
shift
goto arg_loop

:: ## done_args
:: Continues execution after command-line argument parsing completes.
:done_args

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\synthesize_branding.ps1" -TargetSpec "%TARGET_SPEC%" -OutputDir "%OUTPUT_DIR%"
exit /b %ERRORLEVEL%
