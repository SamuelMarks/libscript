@echo off
:: # state.cmd
:: ## Overview
:: Network control library module for state.
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
if /i "%~1"=="tls" goto netctl_set_tls
if /i "%~1"=="cert-store-dir" goto netctl_set_cert_store_dir
if /i "%~1"=="cert_store_dir" goto netctl_set_cert_store_dir
if /i "%~1"=="acme-webroot" goto netctl_set_acme_webroot
if /i "%~1"=="acme_webroot" goto netctl_set_acme_webroot
if /i "%~1"=="proxy-connect-timeout" goto netctl_set_proxy_connect_timeout
if /i "%~1"=="proxy_connect_timeout" goto netctl_set_proxy_connect_timeout
if /i "%~1"=="proxy-send-timeout" goto netctl_set_proxy_send_timeout
if /i "%~1"=="proxy_send_timeout" goto netctl_set_proxy_send_timeout
if /i "%~1"=="proxy-read-timeout" goto netctl_set_proxy_read_timeout
if /i "%~1"=="proxy_read_timeout" goto netctl_set_proxy_read_timeout
if /i "%~1"=="proxy-buffering" goto netctl_set_proxy_buffering
if /i "%~1"=="proxy_buffering" goto netctl_set_proxy_buffering
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
    echo {"domain":"_","listen":[],"tls":"","cert_store_dir":"","acme_webroot":"","routes":{}} > "%NETCTL_STATE_FILE%"
) else (
    for %%I in ("%NETCTL_STATE_FILE%") do if %%~zI equ 0 (
        echo {"domain":"_","listen":[],"tls":"","cert_store_dir":"","acme_webroot":"","routes":{}} > "%NETCTL_STATE_FILE%"
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

:: ## netctl_set_tls
:: Sets the TLS provider mode in the state file.
:netctl_set_tls
call :init
jq --arg t "%~2" ".tls = $t" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## netctl_set_cert_store_dir
:: Sets the persistent read-only certificate store directory in the state file.
:netctl_set_cert_store_dir
call :init
jq --arg c "%~2" ".cert_store_dir = $c" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## netctl_set_acme_webroot
:: Sets the ACME HTTP-01 challenge webroot directory in the state file.
:netctl_set_acme_webroot
call :init
jq --arg w "%~2" ".acme_webroot = $w" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## netctl_set_proxy_connect_timeout
:: Sets the upstream proxy connect timeout in the state file.
:netctl_set_proxy_connect_timeout
call :init
jq --arg t "%~2" ".proxy_connect_timeout = $t" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## netctl_set_proxy_send_timeout
:: Sets the upstream proxy send timeout in the state file.
:netctl_set_proxy_send_timeout
call :init
jq --arg t "%~2" ".proxy_send_timeout = $t" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## netctl_set_proxy_read_timeout
:: Sets the upstream proxy read timeout in the state file.
:netctl_set_proxy_read_timeout
call :init
jq --arg t "%~2" ".proxy_read_timeout = $t" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## netctl_set_proxy_buffering
:: Sets the upstream proxy buffering mode in the state file.
:netctl_set_proxy_buffering
call :init
jq --arg b "%~2" ".proxy_buffering = $b" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## listen
:: Records a port listen directive in the netctl state file.
:listen
call :init
jq --arg p "%~2" ".listen += [$p] | .listen |= unique" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0

:: ## static
:: Records a static file serving route in the netctl state file.
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
:: Records a reverse-proxy route mapping in the netctl state file.
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
:: Records a URL rewrite rule in the netctl state file.
:rewrite
call :init
jq --arg p "%~2" --arg pt "%~3" ".routes[$p] = {\"type\": \"rewrite\", \"pattern\": $pt}" "%NETCTL_STATE_FILE%" > "%NETCTL_STATE_FILE%.tmp"
move /Y "%NETCTL_STATE_FILE%.tmp" "%NETCTL_STATE_FILE%" >nul
exit /b 0
