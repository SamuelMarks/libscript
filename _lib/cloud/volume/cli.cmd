@echo off
:: # cli.cmd
::
:: ## Overview
:: Volume component CLI for Block Storage operations on Windows.
::
:: ## Usage
:: libscript volume [create|delete|list|attach|detach] [--cloud aws|gcp|azure] [--volume-id id] [--name name] [--size gb] [--zone zone] [--type type] [--node-id id] [--device path]
set "THIS_FILE=%~f0"

set "CMD=%~1"
if not "%CMD%"=="" shift

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~1"=="" goto validate_args
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
:: Executes validate_args functionality.
:validate_args
if "%CMD%"=="" (
    echo Error: Missing command for volume (create^|delete^|list^|attach^|detach^). >&2
    exit /b 1
)

if "%CMD%"=="create" goto execute
if "%CMD%"=="delete" goto execute
if "%CMD%"=="list" goto execute
if "%CMD%"=="attach" goto execute
if "%CMD%"=="detach" goto execute

echo Error: Unknown volume command '%CMD%' >&2
exit /b 1

:: ## execute
:: Executes execute functionality.
:execute
if "%LIBSCRIPT_CLOUD%"=="" (
    echo Error: --cloud (or LIBSCRIPT_CLOUD) is required. >&2
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
        echo Error: --volume-id (or LIBSCRIPT_VOLUME_ID) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_volume_delete "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_ID%"
    exit /b %errorlevel%
)

if "%CMD%"=="attach" (
    if "%LIBSCRIPT_VOLUME_ID%"=="" (
        echo Error: --volume-id (or LIBSCRIPT_VOLUME_ID) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_volume_attach "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_ID%" "%LIBSCRIPT_NODE_ID%" "%LIBSCRIPT_DEVICE%"
    exit /b %errorlevel%
)

if "%CMD%"=="detach" (
    if "%LIBSCRIPT_VOLUME_ID%"=="" (
        echo Error: --volume-id (or LIBSCRIPT_VOLUME_ID) is required for %CMD%. >&2
        exit /b 1
    )
    call "%~dp0api.cmd" :libscript_volume_detach "%LIBSCRIPT_CLOUD%" "%LIBSCRIPT_VOLUME_ID%" "%LIBSCRIPT_NODE_ID%"
    exit /b %errorlevel%
)

exit /b 0
