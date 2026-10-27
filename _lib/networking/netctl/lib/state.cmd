@echo off
:: # state.cmd
::
:: ## Overview
:: Network control library module for state.
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

if /i "%~1"=="init" goto init
if /i "%~1"=="domain" goto domain
if /i "%~1"=="listen" goto listen
if /i "%~1"=="static" goto static
if /i "%~1"=="spa" goto spa
if /i "%~1"=="proxy" goto proxy
if /i "%~1"=="ws" goto ws
if /i "%~1"=="rewrite" goto rewrite
exit /b 1

:: ## init
:: Initializes default environment variables and module state.
:init
if not exist "%NETCTL_STATE_FILE%" (
    echo {"domain":"_","listen":[],"routes":{}} > "%NETCTL_STATE_FILE%"
) else (
    for %%I in ("%NETCTL_STATE_FILE%") do if %%~zI equ 0 (
        echo {"domain":"_","listen":[],"routes":{}} > "%NETCTL_STATE_FILE%"
    )
)
exit /b 0

:: ## domain
:: Sets the server_name / domain in the state file.
:domain
call :init
jq --arg d "%~2" ".domain = $d" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## listen
:: Performs the listen operation and updates component state.
:listen
call :init
jq --arg p "%~2" ".listen += [$p] | .listen |= unique" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## static
:: Performs the static operation and updates component state.
:static
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"static\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## spa
:: Registers a Single-Page Application (SPA) static route with index.html fallback.
:spa
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"spa\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## proxy
:: Performs the proxy operation and updates component state.
:proxy
call :init
jq --arg p "%~2" --arg t "%~3" ".routes[$p] = {\"type\": \"proxy\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## ws
:: Registers a WebSocket reverse proxy route with Upgrade headers.
:ws
call :init
set "ws_target=%~3"
set "ws_target=!ws_target:ws://=http://!"
set "ws_target=!ws_target:wss://=https://!"
jq --arg p "%~2" --arg t "!ws_target!" ".routes[$p] = {\"type\": \"ws\", \"target\": $t}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## rewrite
:: Performs the rewrite operation and updates component state.
:rewrite
call :init
jq --arg p "%~2" --arg pt "%~3" ".routes[$p] = {\"type\": \"rewrite\", \"pattern\": $pt}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0
