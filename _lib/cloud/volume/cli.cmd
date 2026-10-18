@echo off
:: # cli.cmd
::
:: ## Overview
:: Volume component CLI for Block Storage operations on Windows.
::
:: ## Usage
:: libscript volume [create|delete|list|attach|detach] [--cloud aws|gcp|azure] [--volume-id id] [--name name] [--size gb] [--zone zone] [--type type] [--node-id id] [--device path]
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
if /i "%~1"=="volume" (
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
if "%~1"=="--cloud" ( set "LIBSCRIPT_CLOUD=%~2" & shift & shift & goto parse_args )
if "%~1"=="--volume-id" ( set "LIBSCRIPT_VOLUME_ID=%~2" & shift & shift & goto parse_args )
if "%~1"=="--size" ( set "LIBSCRIPT_VOLUME_SIZE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--name" ( set "LIBSCRIPT_VOLUME_NAME=%~2" & shift & shift & goto parse_args )
if "%~1"=="--zone" ( set "LIBSCRIPT_VOLUME_ZONE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--type" ( set "LIBSCRIPT_VOLUME_TYPE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--node-id" ( set "LIBSCRIPT_NODE_ID=%~2" & shift & shift & goto parse_args )
if "%~1"=="--device" ( set "LIBSCRIPT_DEVICE=%~2" & shift & shift & goto parse_args )

echo %~1 | findstr /b /c:"--cloud=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_CLOUD=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--volume-id=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_VOLUME_ID=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--size=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_VOLUME_SIZE=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--name=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_VOLUME_NAME=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--zone=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_VOLUME_ZONE=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--type=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_VOLUME_TYPE=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--node-id=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_NODE_ID=%%A" & shift & goto parse_args )
echo %~1 | findstr /b /c:"--device=" >nul
if not errorlevel 1 ( for /f "tokens=2 delims==" %%A in ("%~1") do set "LIBSCRIPT_DEVICE=%%A" & shift & goto parse_args )

echo Error: Unknown argument '%~1' >&2
exit /b 1

:: ## validate_args
:: Validates required command-line arguments and configuration parameters.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for volume ^(create^|delete^|list^|attach^|detach^). >&2
    exit /b 1
)

if /i "%CMD%"=="install" (
    echo Cloud components are operational wrappers and do not require installation.
    exit /b 0
)
if /i "%CMD%"=="test" (
    echo Running mock test for volume...
    exit /b 0
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute
if "%CMD%"=="attach" goto execute
if "%CMD%"=="detach" goto execute

echo Error: Unknown volume command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes the primary orchestration workflow for this script.
:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud ^(or LIBSCRIPT_CLOUD^) is required. >&2
    exit /b 1
)

if "%CMD%"=="list" (
    call "%~dp0api.cmd" :libscript_volume_list "%LIBSCRIPT_CLOUD%"
    exit /b %errorlevel%
)

if "%CMD%"=="create" (
    call "%~dp0api.cmd" :libscript_volume_create "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_SIZE%" "%LIBSCRIPT_VOLUME_ZONE%" "%LIBSCRIPT_VOLUME_TYPE%" "%LIBSCRIPT_VOLUME_NAME%"
    exit /b %errorlevel%
)

if "%CMD%"=="delete" (
    if "%LIBSCRIPT_VOLUME_ID%"=="" (
        echo Error: --volume-id ^(or LIBSCRIPT_VOLUME_ID^) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_volume_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_ID%"
    exit /b %errorlevel%
)

if "%CMD%"=="attach" (
    if "%LIBSCRIPT_VOLUME_ID%"=="" (
        echo Error: --volume-id ^(or LIBSCRIPT_VOLUME_ID^) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_volume_attach "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_ID%" "%LIBSCRIPT_NODE_ID%" "%LIBSCRIPT_DEVICE%"
    exit /b %errorlevel%
)

if "%CMD%"=="detach" (
    if "%LIBSCRIPT_VOLUME_ID%"=="" (
        echo Error: --volume-id ^(or LIBSCRIPT_VOLUME_ID^) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_volume_detach "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_ID%" "%LIBSCRIPT_NODE_ID%"
    exit /b %errorlevel%
)

exit /b 0
