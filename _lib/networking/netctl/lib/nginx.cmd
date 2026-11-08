@echo off
:: # nginx.cmd
:: ## Overview
:: Network control library module for nginx on Windows. Supports SPA try_files, WebSocket Upgrade headers, domain server_name, and WASM MIME types.
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
call :netctl_nginx_emit %*
exit /b !ERRORLEVEL!

:: ## netctl_nginx_emit
:: Renders the accumulated netctl routing state as an Nginx server configuration on Windows.
:netctl_nginx_emit
if "%NETCTL_STATE_FILE%"=="" set NETCTL_STATE_FILE=.netctl.json

if not exist "%NETCTL_STATE_FILE%" (
    echo Error: State file '%NETCTL_STATE_FILE%' not found. >&2
    exit /b 1
)

set "DOMAIN=_"
for /f "delims=" %%d in ('jq -r ".domain // \"_\"" "%NETCTL_STATE_FILE%" 2^>nul') do set "DOMAIN=%%d"
if "!DOMAIN!"=="" set "DOMAIN=_"
if "!DOMAIN!"=="null" set "DOMAIN=_"

set "TLS_MODE="
for /f "delims=" %%t in ('jq -r ".tls // empty" "%NETCTL_STATE_FILE%" 2^>nul') do set "TLS_MODE=%%t"
if "!TLS_MODE!"=="null" set "TLS_MODE="

set "CERT_STORE=%CERT_STORE_DIR%"
if "!CERT_STORE!"=="" (
    set "_NGX_DEF_MOUNT=%DATA_DISK_MOUNT%"
    if "!_NGX_DEF_MOUNT!"=="" set "_NGX_DEF_MOUNT=%DATA_MOUNT_DIR%"
    if "!_NGX_DEF_MOUNT!"=="" set "_NGX_DEF_MOUNT=/mnt/data"
    set "CERT_STORE=!_NGX_DEF_MOUNT!/certs"
)
for /f "delims=" %%c in ('jq -r ".cert_store_dir // empty" "%NETCTL_STATE_FILE%" 2^>nul') do (
    if not "%%c"=="" if not "%%c"=="null" set "CERT_STORE=%%c"
)

set "ACME_WEBROOT=!CERT_STORE!/acme-webroot"
for /f "delims=" %%w in ('jq -r ".acme_webroot // empty" "%NETCTL_STATE_FILE%" 2^>nul') do (
    if not "%%w"=="" if not "%%w"=="null" set "ACME_WEBROOT=%%w"
)

set "NETCTL_PROXY_CONNECT_TIMEOUT=%NETCTL_PROXY_CONNECT_TIMEOUT%"
for /f "delims=" %%p in ('jq -r ".proxy_connect_timeout // empty" "%NETCTL_STATE_FILE%" 2^>nul') do (
    if not "%%p"=="" if not "%%p"=="null" set "NETCTL_PROXY_CONNECT_TIMEOUT=%%p"
)
if "!NETCTL_PROXY_CONNECT_TIMEOUT!"=="" set "NETCTL_PROXY_CONNECT_TIMEOUT=60s"
echo "!NETCTL_PROXY_CONNECT_TIMEOUT!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "NETCTL_PROXY_CONNECT_TIMEOUT=!NETCTL_PROXY_CONNECT_TIMEOUT!s"

set "NETCTL_PROXY_SEND_TIMEOUT=%NETCTL_PROXY_SEND_TIMEOUT%"
for /f "delims=" %%p in ('jq -r ".proxy_send_timeout // empty" "%NETCTL_STATE_FILE%" 2^>nul') do (
    if not "%%p"=="" if not "%%p"=="null" set "NETCTL_PROXY_SEND_TIMEOUT=%%p"
)
if "!NETCTL_PROXY_SEND_TIMEOUT!"=="" set "NETCTL_PROXY_SEND_TIMEOUT=300s"
echo "!NETCTL_PROXY_SEND_TIMEOUT!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "NETCTL_PROXY_SEND_TIMEOUT=!NETCTL_PROXY_SEND_TIMEOUT!s"

set "NETCTL_PROXY_READ_TIMEOUT=%NETCTL_PROXY_READ_TIMEOUT%"
for /f "delims=" %%p in ('jq -r ".proxy_read_timeout // empty" "%NETCTL_STATE_FILE%" 2^>nul') do (
    if not "%%p"=="" if not "%%p"=="null" set "NETCTL_PROXY_READ_TIMEOUT=%%p"
)
if "!NETCTL_PROXY_READ_TIMEOUT!"=="" set "NETCTL_PROXY_READ_TIMEOUT=300s"
echo "!NETCTL_PROXY_READ_TIMEOUT!" | findstr /R "^[0-9][0-9]*$" >nul 2>&1
if not errorlevel 1 set "NETCTL_PROXY_READ_TIMEOUT=!NETCTL_PROXY_READ_TIMEOUT!s"

set "NETCTL_PROXY_BUFFERING=%NETCTL_PROXY_BUFFERING%"
for /f "delims=" %%p in ('jq -r ".proxy_buffering // empty" "%NETCTL_STATE_FILE%" 2^>nul') do (
    if not "%%p"=="" if not "%%p"=="null" set "NETCTL_PROXY_BUFFERING=%%p"
)
if "!NETCTL_PROXY_BUFFERING!"=="" set "NETCTL_PROXY_BUFFERING=off"
if /i "!NETCTL_PROXY_BUFFERING!"=="true" set "NETCTL_PROXY_BUFFERING=on"
if /i "!NETCTL_PROXY_BUFFERING!"=="1" set "NETCTL_PROXY_BUFFERING=on"
if /i "!NETCTL_PROXY_BUFFERING!"=="false" set "NETCTL_PROXY_BUFFERING=off"
if /i "!NETCTL_PROXY_BUFFERING!"=="0" set "NETCTL_PROXY_BUFFERING=off"

set "LE_ETC_DIR=%LETSENCRYPT_ETC_DIR%"
if "!LE_ETC_DIR!"=="" (
    set "_NGX_ETC=%LIBSCRIPT_ETC_DIR%"
    if "!_NGX_ETC!"=="" set "_NGX_ETC=/etc"
    set "LE_ETC_DIR=!_NGX_ETC!/letsencrypt"
)

echo server {

for /f "delims=" %%i in ('jq -r ".listen[]" "%NETCTL_STATE_FILE%"') do (
    if "%%i"=="443" (
        if not "%NETCTL_BOOTSTRAP_HTTP_ONLY%"=="1" (
            if exist "!CERT_STORE!\live\!DOMAIN!\fullchain.pem" (
                echo     listen 443 ssl;
                echo     ssl_certificate !CERT_STORE!/live/!DOMAIN!/fullchain.pem;
                echo     ssl_certificate_key !CERT_STORE!/live/!DOMAIN!/privkey.pem;
                echo     ssl_protocols TLSv1.2 TLSv1.3;
            ) else if exist "!LE_ETC_DIR!\live\!DOMAIN!\fullchain.pem" (
                echo     listen 443 ssl;
                echo     ssl_certificate !LE_ETC_DIR!/live/!DOMAIN!/fullchain.pem;
                echo     ssl_certificate_key !LE_ETC_DIR!/live/!DOMAIN!/privkey.pem;
                echo     ssl_protocols TLSv1.2 TLSv1.3;
            ) else if not "!TLS_MODE!"=="letsencrypt" (
                echo     listen 443;
            )
        )
    ) else (
        echo     listen %%i;
    )
)

echo     server_name !DOMAIN!;
echo     include mime.types;
echo     types {
echo         application/wasm wasm;
echo     }
echo.
echo     location ^^~ /.well-known/acme-challenge/ {
echo         root !ACME_WEBROOT!;
echo         default_type "text/plain";
echo         try_files $uri =404;
echo     }

set "_JQ_FLT=%TEMP%\netctl_nginx_%RANDOM%.jq"
> "!_JQ_FLT!" echo .routes ^| to_entries[] ^| "\(.key)|\(.value.type)|\(.value.target // "")|\(.value.pattern // "")"
for /f "usebackq tokens=1,2,3,4 delims=|" %%a in (`jq -r -f "!_JQ_FLT!" "%NETCTL_STATE_FILE%"`) do (
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
        echo         proxy_connect_timeout !NETCTL_PROXY_CONNECT_TIMEOUT!;
        echo         proxy_send_timeout !NETCTL_PROXY_SEND_TIMEOUT!;
        echo         proxy_read_timeout !NETCTL_PROXY_READ_TIMEOUT!;
        echo         proxy_buffering !NETCTL_PROXY_BUFFERING!;
        echo         proxy_cache off;
        echo         proxy_set_header Upgrade $http_upgrade;
        echo         proxy_set_header Connection "";
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
        echo         proxy_connect_timeout !NETCTL_PROXY_CONNECT_TIMEOUT!;
        echo         proxy_send_timeout !NETCTL_PROXY_SEND_TIMEOUT!;
        echo         proxy_read_timeout !NETCTL_PROXY_READ_TIMEOUT!;
        echo         proxy_buffering !NETCTL_PROXY_BUFFERING!;
        echo         proxy_cache off;
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
if exist "!_JQ_FLT!" del /f /q "!_JQ_FLT!" >nul 2>&1

echo }
exit /b 0
