@echo off
:: # service.cmd
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status, configure, override-env) and persistent REDIS_DATA_DIR / VALKEY_DATA_DIR configuration for the redis component on Windows.
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
set "ACTION=%~1"
if "%ACTION%"=="" set "ACTION=status"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "REDIS_EXE=%LIBSCRIPT_HOME%\redis\latest\bin\redis-server.exe"
if not exist "%REDIS_EXE%" set "REDIS_EXE=%LIBSCRIPT_HOME%\redis\latest\redis-server.exe"
if not exist "%REDIS_EXE%" (
    for /d %%D in ("%LIBSCRIPT_HOME%\redis\latest\redis*") do (
        if exist "%%~fD\bin\redis-server.exe" set "REDIS_EXE=%%~fD\bin\redis-server.exe"
    )
)

if /i "%ACTION%"=="configure" (
    call :configure_redis_storage "%~2"
    exit /b !ERRORLEVEL!
)
if /i "%ACTION%"=="override-env" (
    call :configure_redis_storage "%~2"
    exit /b !ERRORLEVEL!
)
if /i "%ACTION%"=="start" (
    call :configure_redis_storage
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" is-active Redis >nul 2>&1 && exit /b 0
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" start Redis >nul 2>&1 && exit /b 0
    if exist "%REDIS_EXE%" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\_common\daemon_launcher.ps1" -Port 6379 -Executable "%REDIS_EXE%" 2>nul
    )
    exit /b 0
)
if /i "%ACTION%"=="stop" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" stop Redis >nul 2>&1
    taskkill /F /IM redis-server.exe >nul 2>&1
    exit /b 0
)
if /i "%ACTION%"=="restart" (
    call :configure_redis_storage
    call "%~f0" stop
    call "%~f0" start
    exit /b 0
)
if /i "%ACTION%"=="status" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service.cmd" is-active Redis >nul 2>&1 && (echo [RUNNING] Redis & exit /b 0)
    powershell -NoProfile -Command "if (Get-Process redis-server -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" 2>nul && (echo [RUNNING] redis-server.exe & exit /b 0)
    echo [STOPPED] redis
    exit /b 1
)
exit /b 0

:: ## configure_redis_storage
:: Ensures the persistent Redis/Valkey data directory exists, grants service ACLs, and persists REDIS_DATA_DIR and VALKEY_DATA_DIR overrides on Windows.
:configure_redis_storage
set "_CRS_DIR=%~1"
if /i "!_CRS_DIR!"=="redis" set "_CRS_DIR="
if /i "!_CRS_DIR!"=="redis-server" set "_CRS_DIR="
if /i "!_CRS_DIR!"=="valkey" set "_CRS_DIR="
if /i "!_CRS_DIR!"=="valkey-server" set "_CRS_DIR="
if /i "!_CRS_DIR!"=="libscript_redis" set "_CRS_DIR="
if "!_CRS_DIR!"=="" set "_CRS_DIR=!REDIS_DATA_DIR!"
if "!_CRS_DIR!"=="" set "_CRS_DIR=!VALKEY_DATA_DIR!"
if "!_CRS_DIR!"=="" exit /b 0
set "REDIS_DATA_DIR=!_CRS_DIR!"
set "VALKEY_DATA_DIR=!_CRS_DIR!"
if not exist "!REDIS_DATA_DIR!" mkdir "!REDIS_DATA_DIR!" >nul 2>&1
icacls "!REDIS_DATA_DIR!" /grant "*S-1-5-32-544:(OI)(CI)F" /grant "*S-1-5-18:(OI)(CI)F" /T /C /Q >nul 2>&1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\service_install.cmd" override-env "Redis" "REDIS_DATA_DIR=!REDIS_DATA_DIR!" "VALKEY_DATA_DIR=!VALKEY_DATA_DIR!" >nul 2>&1
exit /b 0
