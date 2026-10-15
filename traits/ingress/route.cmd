@echo off
:: # route.cmd
::
:: ## Overview
:: Queries hooks\announce and drives _lib\networking\netctl\cli.cmd on Windows.
::
:: ## Usage
:: traits\ingress\route.cmd <nginx|caddy|apache|iis|traefik> [component] [path] [output_file]

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

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "FORMAT=%~1"
set "ROUTE_PATH=%~3"
if "%FORMAT%"=="" set "FORMAT=nginx"
if "%ROUTE_PATH%"=="" set "ROUTE_PATH=/"

call "%LIBSCRIPT_ROOT_DIR%\_lib\networking\netctl\cli.cmd" --listen 80 --proxy "%ROUTE_PATH%" "http://127.0.0.1:8080" --emit "%FORMAT%"
exit /b %errorlevel%

:: ## help
:: Prints usage help for route.cmd.
:help
echo Usage: route.cmd ^<nginx^|caddy^|apache^|iis^|traefik^> [component] [path] [output_file]
exit /b 0
