@echo off
:: # nginx.cmd
::
:: ## Overview
:: Network control library module for nginx.
:: 
:: ## Usage
:: This script provides internal functions and should not be executed directly.

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

if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

echo server {

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     listen %%i;
)

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    echo     location %%a {
    if "%%b"=="static" (
        echo         alias %%c/;
    ) else if "%%b"=="proxy" (
        echo         proxy_pass %%c;
        echo         proxy_set_header Host $host;
        echo         proxy_set_header X-Real-IP $remote_addr;
    ) else if "%%b"=="rewrite" (
        echo         rewrite %%d break;
    )
    echo     }
)

echo }
exit /b 0
