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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:found_root

set "TARGET_SPEC=%~1"
if "%TARGET_SPEC%"=="" (
    echo [ERROR] No stack directory or packaging.json specified >&2
    exit /b 1
)
shift

set "OUTPUT_DIR="
:arg_loop
if "%~1"=="" goto done_args
if /i "%~1"=="--output-dir" ( set "OUTPUT_DIR=%~2" & shift & shift & goto arg_loop )
if /i "%~1"=="-o" ( set "OUTPUT_DIR=%~2" & shift & shift & goto arg_loop )
set "OUTPUT_DIR=%~1"
shift
goto arg_loop

:done_args

powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\synthesize_branding.ps1" -TargetSpec "%TARGET_SPEC%" -OutputDir "%OUTPUT_DIR%"
exit /b %ERRORLEVEL%
