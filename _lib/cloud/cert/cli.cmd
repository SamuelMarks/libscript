@echo off
:: # cli.cmd
::
:: ## Overview
:: Cert component CLI for SSL certificate operations on Windows.
::
:: ## Usage
:: libscript cert [create|delete|list] [--cloud aws|gcp|azure] [--domain name]
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

set "CMD=%~1"
if not "%CMD%"=="" shift

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto validate_args
if /i "%~1"=="cert" (
    shift
    goto parse_args
)
if /i "%~1"=="install" (
    shift
    goto parse_args
)
if /i "%~1"=="test" (
    shift
    goto parse_args
)
if /i "%~1"=="setup" (
    shift
    goto parse_args
)
if /i "%~1"=="uninstall" (
    shift
    goto parse_args
)
if "%~1"=="--cloud" (
    set "LIBSCRIPT_CLOUD=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--domain" (
    set "LIBSCRIPT_DOMAIN=%~2"
    shift
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--cloud=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_CLOUD=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--domain=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DOMAIN=%%A"
    shift
    goto parse_args
)
echo Error: Unknown argument '%~1' >&2
exit /b 1

:: ## validate_args
:: Validates required command-line arguments and configuration parameters.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for cert ^(create^|delete^|list^). >&2
    exit /b 1
)

if /i "%CMD%"=="install" (
    echo Cloud components are operational wrappers and do not require installation.
    exit /b 0
)
if /i "%CMD%"=="test" (
    echo Running mock test for cert...
    exit /b 0
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute

echo Error: Unknown cert command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes the primary orchestration workflow for this script.
:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud ^(or LIBSCRIPT_CLOUD^) is required. >&2
    exit /b 1
)

if "%CMD%"=="list" (
    call "%~dp0api.cmd" :libscript_cert_list "%LIBSCRIPT_CLOUD%"
    exit /b %errorlevel%
)

if "%LIBSCRIPT_DOMAIN%"=="" (
    echo Error: --domain ^(or LIBSCRIPT_DOMAIN^) is required for %CMD%. >&2
    exit /b 1
)

if "%CMD%"=="create" (
    call "%~dp0api.cmd" :libscript_cert_create "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DOMAIN%"
    exit /b %errorlevel%
)
if "%CMD%"=="delete" (
    call "%~dp0api.cmd" :libscript_cert_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DOMAIN%"
    exit /b %errorlevel%
)

exit /b 0
