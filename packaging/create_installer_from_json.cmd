@echo off
:: # create_installer_from_json.cmd
::
:: ## Overview
:: Generates an installer package based on a JSON schema definition on Windows.
:: 
:: ## Usage
:: Execute this script with a JSON manifest to build an installer.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\.."
)

set "ALL_DEPS=0"
set "OUTPUT_FOLDER=%LIBSCRIPT_ROOT_DIR%\tmp"
set "FILENAME="

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~1"=="" goto validate_args
if /i "%~1"=="-h" goto show_help
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="/?" goto show_help
if /i "%~1"=="-a" (
    set "ALL_DEPS=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-f" (
    set "FILENAME=%~2"
    shift
    shift
    goto parse_args
)
if /i "%~1"=="-o" (
    set "OUTPUT_FOLDER=%~2"
    shift
    shift
    goto parse_args
)
shift
goto parse_args

:: ## show_help
:: Executes show_help functionality.
:show_help
echo Create install scripts from JSON.
echo   -a whether to install all dependencies (required AND optional)
echo   -f filename
echo   -o output folder (defaults to .\tmp)
echo   -h show help text
exit /b 0

:: ## validate_args
:: Executes validate_args functionality.
:validate_args
if "%FILENAME%"=="" (
    call :show_help
    echo Error: JSON file must be specified with -f 1>&2
    exit /b 2
)
if not exist "%FILENAME%" (
    call :show_help
    echo Error: JSON file specified with -f must exist 1>&2
    exit /b 2
)

echo Generating installer from %FILENAME% into %OUTPUT_FOLDER%...
if not exist "%OUTPUT_FOLDER%" mkdir "%OUTPUT_FOLDER%"
exit /b 0
