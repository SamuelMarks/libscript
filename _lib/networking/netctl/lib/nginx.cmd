@echo off
:: # nginx.cmd
::
:: ## Overview
:: Network control library module for nginx on Windows.
:: Supports SPA try_files, WebSocket Upgrade headers, domain server_name, and WASM MIME types.
:: 
:: ## Usage
:: This script provides internal functions and should not be executed directly.

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

if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

set "DOMAIN=_"
for /f "delims=" %%d in ('jq -r ".domain // \"_\"" "%NETCTL_STATE_FILE%" 2^>nul') do set "DOMAIN=%%d"
if "!DOMAIN!"=="" set "DOMAIN=_"
if "!DOMAIN!"=="null" set "DOMAIN=_"

echo server {

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    echo     listen %%i;
)

echo     server_name !DOMAIN!;
echo     include mime.types;
echo     types {
echo         application/wasm wasm;
echo     }

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    echo     location %%a {
    if "%%b"=="static" (
        if "%%a"=="/" (
            echo         root %%c;
            echo         index index.html;
            echo         try_files $uri $uri/ /index.html;
        ) else (
            echo         alias %%c/;
        )
    ) else if "%%b"=="spa" (
        if "%%a"=="/" (
            echo         root %%c;
            echo         index index.html;
            echo         try_files $uri $uri/ /index.html;
        ) else (
            echo         alias %%c/;
            echo         index index.html;
            echo         try_files $uri $uri/ %%a/index.html;
        )
    ) else if "%%b"=="proxy" (
        set "p_target=%%c"
        set "p_target=!p_target:ws://=http://!"
        set "p_target=!p_target:wss://=https://!"
        echo         proxy_pass !p_target!;
        echo         proxy_http_version 1.1;
        echo         proxy_set_header Upgrade $http_upgrade;
        echo         proxy_set_header Connection "upgrade";
        echo         proxy_set_header Host $host;
        echo         proxy_set_header X-Real-IP $remote_addr;
        echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        echo         proxy_set_header X-Forwarded-Proto $scheme;
    ) else if "%%b"=="ws" (
        set "p_target=%%c"
        set "p_target=!p_target:ws://=http://!"
        set "p_target=!p_target:wss://=https://!"
        echo         proxy_pass !p_target!;
        echo         proxy_http_version 1.1;
        echo         proxy_set_header Upgrade $http_upgrade;
        echo         proxy_set_header Connection "upgrade";
        echo         proxy_set_header Host $host;
        echo         proxy_set_header X-Real-IP $remote_addr;
        echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        echo         proxy_set_header X-Forwarded-Proto $scheme;
    ) else if "%%b"=="rewrite" (
        echo         rewrite %%d break;
    )
    echo     }
)

echo }
exit /b 0
