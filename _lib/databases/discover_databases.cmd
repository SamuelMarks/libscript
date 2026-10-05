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

:: ## Overview
:: Discovers active database instances on Windows.
:: Uses sc.exe and netstat for probing.
::
:: ## Usage
::   call discover_databases.cmd [--json | --eval | --check --engine <type>]

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "MODE=eval"
set "TARGET_ENGINE="

:parse_args
if "%~1"=="" goto run_discovery
if "%~1"=="--json" ( set "MODE=json" & shift & goto parse_args )
if "%~1"=="--eval" ( set "MODE=eval" & shift & goto parse_args )
if "%~1"=="--check" ( set "MODE=check" & shift & goto parse_args )
if "%~1"=="--engine" ( set "TARGET_ENGINE=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:run_discovery
set "FOUND_MYSQL=0"
set "FOUND_PG=0"
set "FOUND_MONGO=0"
set "FOUND_REDIS=0"

:: ## TCP Port Probing via netstat
netstat -an | findstr "LISTENING" | findstr ":3306 " >nul && set "FOUND_MYSQL=1"
netstat -an | findstr "LISTENING" | findstr ":5432 " >nul && set "FOUND_PG=1"
netstat -an | findstr "LISTENING" | findstr ":27017 " >nul && set "FOUND_MONGO=1"
netstat -an | findstr "LISTENING" | findstr ":6379 " >nul && set "FOUND_REDIS=1"

:: ## Service Probing via sc.exe
sc.exe query MySQL80 >nul 2>&1 && set "FOUND_MYSQL=1"
sc.exe query PostgreSQL >nul 2>&1 && set "FOUND_PG=1"
sc.exe query MongoDB >nul 2>&1 && set "FOUND_MONGO=1"
sc.exe query Redis >nul 2>&1 && set "FOUND_REDIS=1"

if "%MODE%"=="check" (
    if "%TARGET_ENGINE%"=="mysql" ( if "!FOUND_MYSQL!"=="1" exit /b 0 else exit /b 1 )
    if "%TARGET_ENGINE%"=="mariadb" ( if "!FOUND_MYSQL!"=="1" exit /b 0 else exit /b 1 )
    if "%TARGET_ENGINE%"=="postgres" ( if "!FOUND_PG!"=="1" exit /b 0 else exit /b 1 )
    if "%TARGET_ENGINE%"=="mongodb" ( if "!FOUND_MONGO!"=="1" exit /b 0 else exit /b 1 )
    if "%TARGET_ENGINE%"=="redis" ( if "!FOUND_REDIS!"=="1" exit /b 0 else exit /b 1 )
    exit /b 1
)

if "%MODE%"=="json" (
    echo [
    set "FIRST=1"
    if "!FOUND_MYSQL!"=="1" (
        echo   {"engine": "mysql", "host": "127.0.0.1", "port": 3306, "is_active": true, "source": "tcp_probe"}
        set "FIRST=0"
    )
    if "!FOUND_PG!"=="1" (
        if "!FIRST!"=="0" echo ,
        echo   {"engine": "postgres", "host": "127.0.0.1", "port": 5432, "is_active": true, "source": "tcp_probe"}
        set "FIRST=0"
    )
    if "!FOUND_MONGO!"=="1" (
        if "!FIRST!"=="0" echo ,
        echo   {"engine": "mongodb", "host": "127.0.0.1", "port": 27017, "is_active": true, "source": "tcp_probe"}
        set "FIRST=0"
    )
    if "!FOUND_REDIS!"=="1" (
        if "!FIRST!"=="0" echo ,
        echo   {"engine": "redis", "host": "127.0.0.1", "port": 6379, "is_active": true, "source": "tcp_probe"}
    )
    echo ]
    exit /b 0
)

if "%MODE%"=="eval" (
    if "!FOUND_MYSQL!"=="1" (
        echo set "DETECTED_DB_ENGINE=mysql"
        echo set "DETECTED_DB_HOST=127.0.0.1"
        echo set "DETECTED_DB_PORT=3306"
    ) else if "!FOUND_PG!"=="1" (
        echo set "DETECTED_DB_ENGINE=postgres"
        echo set "DETECTED_DB_HOST=127.0.0.1"
        echo set "DETECTED_DB_PORT=5432"
    )
)
exit /b 0