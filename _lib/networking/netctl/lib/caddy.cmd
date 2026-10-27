@echo off
:: # caddy.cmd
::
:: ## Overview
:: Network control library module for caddy on Windows.
:: Supports SPA try_files, WebSockets, and static/proxy routes.
:: 
:: ## Usage
:: This script provides internal functions and should not be executed directly.

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

if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

set PORTS=
for /f "delims=" %%p in ('jq -r "if (.listen | length) > 0 then .listen | map(\":\" + .) | join(\", \") else \"localhost\" end" "%NETCTL_STATE_FILE%"') do (
    set PORTS=%%p
)
echo %PORTS% {

for /f "tokens=1,2,3,4 delims=|" %%a in ('jq -r ".routes | to_entries[] | \"\(.key)|\(.value.type)|\(.value.target // \"\")|\(.value.pattern // \"\")\"" "%NETCTL_STATE_FILE%"') do (
    echo.
    if "%%b"=="static" (
        echo     handle %%a* {
        echo         root * %%c
        echo         file_server
        echo     }
    ) else if "%%b"=="spa" (
        echo     handle %%a* {
        echo         root * %%c
        echo         try_files {path} {path}/ /index.html
        echo         file_server
        echo     }
    ) else if "%%b"=="proxy" (
        echo     reverse_proxy %%a* %%c
    ) else if "%%b"=="ws" (
        echo     reverse_proxy %%a* %%c
    ) else if "%%b"=="rewrite" (
        echo     rewrite %%a* %%d
    )
)

echo }
exit /b 0
