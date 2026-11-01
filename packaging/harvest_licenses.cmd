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
if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help

set "PS_CMD=powershell -NoProfile -ExecutionPolicy Bypass"
%PS_CMD% -File "!LIBSCRIPT_ROOT_DIR!\packaging\harvest_licenses.ps1" %*
exit /b %ERRORLEVEL%

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 ^<TARGET_DIR_OR_PLAN^> [OPTIONS]
echo.
echo Options:
echo   --out-dir ^<dir^>       Output directory for harvested license assets
echo   --format ^<type^>       Format to generate: rtf, txt, or all (default: all)
echo   --force               Regenerate licenses even if stamp file exists
echo   --help, -h            Show this help text
exit /b 0
