@echo off
:: # service.cmd
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status, configure, override-env) and persistent POSTGRES_DATA_DIR / PGDATA configuration for the postgres component on Windows.
:: ## Usage
:: service.cmd [action]

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

set "STACK="
call "!SCRIPT_DIR!\env.cmd"
set "_ACT=%~1"
if "!_ACT!"=="" set "_ACT=%ACTION%"
if "!_ACT!"=="" exit /b 0
set "_SVC=%LIBSCRIPT_SERVICE_NAME%"
if "!_SVC!"=="" set "_SVC=postgresql"

if /i "!_ACT!"=="configure" (
    call :configure_postgres_storage "%~2"
    exit /b !ERRORLEVEL!
)
if /i "!_ACT!"=="override-env" (
    call :configure_postgres_storage "%~2"
    exit /b !ERRORLEVEL!
)
if /i "!_ACT!"=="start" call :configure_postgres_storage
if /i "!_ACT!"=="restart" call :configure_postgres_storage
if /i "!_ACT!"=="up" call :configure_postgres_storage
if /i "!_ACT!"=="install-service" call :configure_postgres_storage

exit /b 0

:: ## configure_postgres_storage
:: Ensures the persistent PostgreSQL data directory exists, grants service ACLs, and persists POSTGRES_DATA_DIR and PGDATA overrides on Windows.
:configure_postgres_storage
set "_CPS_DIR=%~1"
if /i "!_CPS_DIR!"=="postgres" set "_CPS_DIR="
if /i "!_CPS_DIR!"=="postgresql" set "_CPS_DIR="
if /i "!_CPS_DIR!"=="libscript_postgres" set "_CPS_DIR="
if "!_CPS_DIR!"=="" set "_CPS_DIR=!POSTGRES_DATA_DIR!"
if "!_CPS_DIR!"=="" set "_CPS_DIR=!PGDATA!"
if "!_CPS_DIR!"=="" exit /b 0
set "POSTGRES_DATA_DIR=!_CPS_DIR!"
set "PGDATA=!_CPS_DIR!"
if not exist "!POSTGRES_DATA_DIR!" mkdir "!POSTGRES_DATA_DIR!" >nul 2>&1
icacls "!POSTGRES_DATA_DIR!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" override-env "!_SVC!" "POSTGRES_DATA_DIR=!POSTGRES_DATA_DIR!" "PGDATA=!PGDATA!" >nul 2>&1
exit /b 0
