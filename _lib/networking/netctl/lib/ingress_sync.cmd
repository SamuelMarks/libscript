@echo off
:: # ingress_sync.cmd
::
:: ## Overview
:: Synchronizes declarative .ingress proxy timeout and buffering rules from libscript.json into netctl on Windows.
::
:: ## Usage
:: _lib\networking\netctl\lib\ingress_sync.cmd [libscript.json] [netctl_args...]

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

call :netctl_synchronize_ingress "%~1" "%~2" "%~3" "%~4"
set "_NIS_RC=!ERRORLEVEL!"
endlocal & (
    set "NETCTL_PROXY_CONNECT_TIMEOUT=%NETCTL_PROXY_CONNECT_TIMEOUT%"
    set "NETCTL_PROXY_SEND_TIMEOUT=%NETCTL_PROXY_SEND_TIMEOUT%"
    set "NETCTL_PROXY_READ_TIMEOUT=%NETCTL_PROXY_READ_TIMEOUT%"
    set "NETCTL_PROXY_BUFFERING=%NETCTL_PROXY_BUFFERING%"
    exit /b %_NIS_RC%
)

:: ## netctl_synchronize_ingress
:: Extracts .ingress proxy settings from libscript.json, normalizes units, exports NETCTL_PROXY_*, and invokes netctl.cmd apply.
:netctl_synchronize_ingress
set "_LSI_JSON=%~1"
if "!_LSI_JSON!"=="" set "_LSI_JSON=libscript.json"
if not exist "!_LSI_JSON!" exit /b 0
set "_LSI_CONN="
set "_LSI_SEND="
set "_LSI_READ="
set "_LSI_BUF="
where jq >nul 2>&1
if not errorlevel 1 (
    jq -e ".ingress != null" "!_LSI_JSON!" >nul 2>&1
    if errorlevel 1 exit /b 0
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_connect_timeout // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_CONN=%%P"
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_send_timeout // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_SEND=%%P"
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_read_timeout // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_READ=%%P"
    for /f "delims=" %%P in ('jq -r ".ingress.proxy_buffering // empty" "!_LSI_JSON!" 2^>nul') do if not "%%P"=="" if not "%%P"=="null" set "_LSI_BUF=%%P"
)
if "!_LSI_CONN!"=="" set "_LSI_CONN=%NETCTL_PROXY_CONNECT_TIMEOUT%"
if "!_LSI_CONN!"=="" set "_LSI_CONN=60s"
echo "!_LSI_CONN!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "_LSI_CONN=!_LSI_CONN!s"

if "!_LSI_SEND!"=="" set "_LSI_SEND=%NETCTL_PROXY_SEND_TIMEOUT%"
if "!_LSI_SEND!"=="" set "_LSI_SEND=300s"
echo "!_LSI_SEND!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "_LSI_SEND=!_LSI_SEND!s"

if "!_LSI_READ!"=="" set "_LSI_READ=%NETCTL_PROXY_READ_TIMEOUT%"
if "!_LSI_READ!"=="" set "_LSI_READ=300s"
echo "!_LSI_READ!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "_LSI_READ=!_LSI_READ!s"

if "!_LSI_BUF!"=="" set "_LSI_BUF=%NETCTL_PROXY_BUFFERING%"
if "!_LSI_BUF!"=="" set "_LSI_BUF=off"
if /i "!_LSI_BUF!"=="true" set "_LSI_BUF=on"
if /i "!_LSI_BUF!"=="1" set "_LSI_BUF=on"
if /i "!_LSI_BUF!"=="false" set "_LSI_BUF=off"
if /i "!_LSI_BUF!"=="0" set "_LSI_BUF=off"

set "NETCTL_PROXY_CONNECT_TIMEOUT=!_LSI_CONN!"
set "NETCTL_PROXY_SEND_TIMEOUT=!_LSI_SEND!"
set "NETCTL_PROXY_READ_TIMEOUT=!_LSI_READ!"
set "NETCTL_PROXY_BUFFERING=!_LSI_BUF!"

if "%LIBSCRIPT_DRY_RUN%"=="1" if "%~2"=="" exit /b 0

set "_LSI_NETCTL=!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\netctl.cmd"
if not exist "!_LSI_NETCTL!" set "_LSI_NETCTL=!LIBSCRIPT_ROOT_DIR!\_lib\networking\netctl\cli.cmd"
set "_LSI_ARGS=%~2 %~3 %~4"
set "_LSI_TRIM=!_LSI_ARGS: =!"
if "!_LSI_TRIM!"=="" set "_LSI_ARGS=--reload"
set "STACK="
call "!_LSI_NETCTL!" apply "!_LSI_JSON!" --proxy-connect-timeout "!NETCTL_PROXY_CONNECT_TIMEOUT!" --proxy-send-timeout "!NETCTL_PROXY_SEND_TIMEOUT!" --proxy-read-timeout "!NETCTL_PROXY_READ_TIMEOUT!" --proxy-buffering "!NETCTL_PROXY_BUFFERING!" !_LSI_ARGS!
exit /b !ERRORLEVEL!
