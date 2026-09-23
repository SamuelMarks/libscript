@echo off
:: # harvest_licenses.cmd
::
:: ## Overview
:: Universal dependency license harvester and bundler for LibScript installers on Windows.
:: Discovers all packaged dependencies, extracts and validates their legal terms,
:: and generates formatted plain-text and Rich Text Format (.rtf) license agreements
:: alongside an indexed licenses_manifest.json for WiX, Inno Setup, and NSIS installers.
::
:: ## Usage
:: call packaging\harvest_licenses.cmd <TARGET_DIR_OR_PLAN> [OPTIONS]
::
:: Options:
::   --out-dir <dir>       Output directory for harvested license assets
::   --format <type>       Format to generate: rtf, txt, or all (default: all)
::   --force               Regenerate licenses even if stamp file exists
::   --help, -h            Show this help text

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
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Traverses parent directories to identify LIBSCRIPT_ROOT_DIR.
set "LIBSCRIPT_ROOT_DIR="
set "CURR_DIR=%SCRIPT_DIR%"
:find_root_loop
if exist "%CURR_DIR%\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=%CURR_DIR%"
    goto root_found
)
if exist "%CURR_DIR%\libscript.sh" (
    set "LIBSCRIPT_ROOT_DIR=%CURR_DIR%"
    goto root_found
)
for %%I in ("%CURR_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%CURR_DIR%" goto root_found
set "CURR_DIR=%PARENT_DIR%"
goto find_root_loop
:root_found

if "%~1"=="" goto show_help
if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help

where sh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sh "%SCRIPT_DIR%\harvest_licenses.sh" %*
    exit /b %ERRORLEVEL%
)

where bash.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    bash "%SCRIPT_DIR%\harvest_licenses.sh" %*
    exit /b %ERRORLEVEL%
)

:: PowerShell fallback if sh/bash not in PATH
set "PS_CMD=powershell -NoProfile -ExecutionPolicy Bypass"
%PS_CMD% -File "%LIBSCRIPT_ROOT_DIR%\packaging\harvest_licenses.ps1" %*
exit /b %ERRORLEVEL%

:show_help
echo Usage: %~nx0 ^<TARGET_DIR_OR_PLAN^> [OPTIONS]
echo.
echo Options:
echo   --out-dir ^<dir^>       Output directory for harvested license assets
echo   --format ^<type^>       Format to generate: rtf, txt, or all (default: all)
echo   --force               Regenerate licenses even if stamp file exists
echo   --help, -h            Show this help text
exit /b 0
