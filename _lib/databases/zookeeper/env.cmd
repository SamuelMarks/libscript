@echo off
:: # env.cmd
::
:: ## Overview
:: Environment configuration script for Apache ZooKeeper on Windows.
::
:: ## Usage
:: call _lib\databases\zookeeper\env.cmd

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
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%ZOOKEEPER_VERSION%"=="" set "ZOOKEEPER_VERSION=latest"
if "%ZOOKEEPER_CLIENT_PORT%"=="" set "ZOOKEEPER_CLIENT_PORT=2181"
set "ZOOKEEPER_HOME=%LIBSCRIPT_HOME%\zookeeper\%ZOOKEEPER_VERSION%"
set "ZOOKEEPER_DATA_DIR=%LIBSCRIPT_HOME%\zookeeper\data"
call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\env_base.cmd" "zookeeper" "%ZOOKEEPER_VERSION%"
endlocal & (
    set "LIBSCRIPT_HOME=%LIBSCRIPT_HOME%"
    set "ZOOKEEPER_VERSION=%ZOOKEEPER_VERSION%"
    set "ZOOKEEPER_CLIENT_PORT=%ZOOKEEPER_CLIENT_PORT%"
    set "ZOOKEEPER_HOME=%ZOOKEEPER_HOME%"
    set "ZOOKEEPER_DATA_DIR=%ZOOKEEPER_DATA_DIR%"
    set "PATH=%PATH%"
)
exit /b 0
