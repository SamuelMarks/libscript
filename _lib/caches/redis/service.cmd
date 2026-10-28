@echo off
:: # service.cmd
::
:: ## Overview
:: Manages background service lifecycle operations (start, stop, status) for the redis component.
::
:: ## Usage
:: service.cmd

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

if /i "%ACTION%"=="start" (
    sc.exe query Redis 2>nul | findstr /C:"RUNNING" >nul 2>&1 && exit /b 0
    sc.exe start Redis >nul 2>&1 && exit /b 0
    if exist "%REDIS_EXE%" (
        powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0..\..\_common\daemon_launcher.ps1" -Port 6379 -Executable "%REDIS_EXE%" 2>nul
    )
    exit /b 0
)
if /i "%ACTION%"=="stop" (
    sc.exe stop Redis >nul 2>&1
    taskkill /F /IM redis-server.exe >nul 2>&1
    exit /b 0
)
if /i "%ACTION%"=="restart" (
    call "%~f0" stop
    call "%~f0" start
    exit /b 0
)
if /i "%ACTION%"=="status" (
    sc.exe query Redis 2>nul | findstr /C:"RUNNING" >nul 2>&1 && (echo [RUNNING] Redis & exit /b 0)
    powershell -NoProfile -Command "if (Get-Process redis-server -ErrorAction SilentlyContinue) { exit 0 } else { exit 1 }" 2>nul && (echo [RUNNING] redis-server.exe & exit /b 0)
    echo [STOPPED] redis
    exit /b 1
)
exit /b 0
