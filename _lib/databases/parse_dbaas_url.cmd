@echo off
:: # parse_dbaas_url.cmd
:: ## Overview
:: Parses a MySQL/MariaDB DBaaS connection URI string into variables on Windows.
:: Supports authentication, ports, database names, and SSL parameters.
::
:: ## Usage
::   call _lib\databases\parse_dbaas_url.cmd <connection_url> [--eval|--json]
::
:: ## Parameters
::   %1 - Database connection URI
::   %2 - Output mode (--eval, --json; default: --eval)

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

if "!LIBSCRIPT_ROOT_DIR!"=="" (
    for %%i in ("%~dp0..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "RAW_URL=%~1"
set "MODE=%~2"
if "%MODE%"=="" set "MODE=--eval"

if "%RAW_URL%"=="" (
    echo [ERROR] No connection URL provided to parse_dbaas_url.cmd >&2
    exit /b 1
)

:: Parse URI using pure Windows Batch token parsing
set "DB_USER=root"
set "DB_PASSWORD="
set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_NAME=wordpress"
set "DB_USE_SSL=0"
set "DB_SSL_CA="
set "DB_SSL_MODE="

set "_REST=%RAW_URL:*://=%"
set "_QUERY="
for /f "tokens=1* delims=?" %%A in ("!_REST!") do (
    set "_REST=%%A"
    set "_QUERY=%%B"
)
if defined _QUERY (
    set "DB_USE_SSL=1"
    for %%Q in ("!_QUERY:&=" "!") do (
        for /f "tokens=1,2 delims==" %%K in ("%%~Q") do (
            if /i "%%K"=="ssl-ca" set "DB_SSL_CA=%%L"
            if /i "%%K"=="ssl_ca" set "DB_SSL_CA=%%L"
            if /i "%%K"=="ssl-mode" set "DB_SSL_MODE=%%L"
            if /i "%%K"=="ssl_mode" set "DB_SSL_MODE=%%L"
        )
    )
)

set "_AUTH_PART="
set "_HOST_PATH=!_REST!"
for /f "tokens=1* delims=@" %%A in ("!_REST!") do (
    if not "%%B"=="" (
        set "_AUTH_PART=%%A"
        set "_HOST_PATH=%%B"
    )
)
if defined _AUTH_PART (
    for /f "tokens=1* delims=:" %%U in ("!_AUTH_PART!") do (
        set "DB_USER=%%U"
        set "DB_PASSWORD=%%V"
    )
)
for /f "tokens=1* delims=/" %%H in ("!_HOST_PATH!") do (
    set "_HOST_PORT=%%H"
    if not "%%I"=="" set "DB_NAME=%%I"
)
for /f "tokens=1,2 delims=:" %%M in ("!_HOST_PORT!") do (
    if not "%%M"=="" set "DB_HOST=%%M"
    if not "%%N"=="" set "DB_PORT=%%N"
)

if /i "%MODE%"=="--json" (
    set "_SSL_BOOL=false"
    if "!DB_USE_SSL!"=="1" set "_SSL_BOOL=true"
    echo {"host":"!DB_HOST!","port":!DB_PORT!,"name":"!DB_NAME!","user":"!DB_USER!","password":"!DB_PASSWORD!","use_ssl":!_SSL_BOOL!,"ssl_ca":"!DB_SSL_CA!","ssl_mode":"!DB_SSL_MODE!"}
) else (
    echo DB_HOST=!DB_HOST!
    echo DB_PORT=!DB_PORT!
    echo DB_NAME=!DB_NAME!
    echo DB_USER=!DB_USER!
    echo DB_PASSWORD=!DB_PASSWORD!
    echo DB_USE_SSL=!DB_USE_SSL!
    echo DB_SSL_CA=!DB_SSL_CA!
    echo DB_SSL_MODE=!DB_SSL_MODE!
)

exit /b 0
