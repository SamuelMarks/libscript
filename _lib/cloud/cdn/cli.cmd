@echo off
:: # cli.cmd
::
:: ## Overview
:: CDN component CLI for website distribution operations on Windows.
::
:: ## Usage
:: libscript cdn [create|delete|list|invalidate] [--cloud aws|gcp|azure] [--bucket name] [--domain custom.tld] [--cert-id id]
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
if /i "%~1"=="cdn" (
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
if "%~1"=="--bucket" (
    set "LIBSCRIPT_BUCKET=%~2"
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
if "%~1"=="--cert-id" (
    set "LIBSCRIPT_CERT_ID=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--dist-id" (
    set "LIBSCRIPT_DIST_ID=%~2"
    shift
    shift
    goto parse_args
)
if "%~1"=="--paths" (
    set "LIBSCRIPT_PATHS=%~2"
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
echo %~1 | findstr /b /c:"--bucket=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_BUCKET=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--domain=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DOMAIN=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--cert-id=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_CERT_ID=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--dist-id=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DIST_ID=%%A"
    shift
    goto parse_args
)
echo %~1 | findstr /b /c:"--paths=" >nul
if not errorlevel 1 (
    for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_PATHS=%%A"
    shift
    goto parse_args
)
echo Error: Unknown argument '%~1' >&2
exit /b 1

:: ## validate_args
:: Validates required command-line arguments and configuration parameters.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for cdn ^(create^|delete^|list^|invalidate^). >&2
    exit /b 1
)

if /i "%CMD%"=="install" (
    echo Cloud components are operational wrappers and do not require installation.
    exit /b 0
)
if /i "%CMD%"=="test" (
    echo Running mock test for cdn...
    exit /b 0
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute
if "%CMD%"=="invalidate" goto execute

echo Error: Unknown cdn command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes the primary orchestration workflow for this script.
:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud ^(or LIBSCRIPT_CLOUD^) is required. >&2
    exit /b 1
)

if "%CMD%"=="list" (
    call "%~dp0api.cmd" :libscript_cdn_list "%LIBSCRIPT_CLOUD%"
    exit /b %errorlevel%
)

if "%CMD%"=="create" (
    if "%LIBSCRIPT_BUCKET%"=="" (
        echo Error: --bucket ^(or LIBSCRIPT_BUCKET^) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_cdn_create "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_BUCKET%" "%LIBSCRIPT_DOMAIN%" "%LIBSCRIPT_CERT_ID%"
    exit /b %errorlevel%
)

if "%CMD%"=="delete" (
    if "%LIBSCRIPT_DIST_ID%"=="" (
        echo Error: --dist-id ^(or LIBSCRIPT_DIST_ID^) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_cdn_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DIST_ID%"
    exit /b %errorlevel%
)

if "%CMD%"=="invalidate" (
    if "%LIBSCRIPT_DIST_ID%"=="" (
        echo Error: --dist-id ^(or LIBSCRIPT_DIST_ID^) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_cdn_invalidate "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_DIST_ID%" "%LIBSCRIPT_PATHS%"
    exit /b %errorlevel%
)

exit /b 0
