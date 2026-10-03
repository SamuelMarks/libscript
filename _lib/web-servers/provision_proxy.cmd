@echo off
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

:: ## Overview
:: Declarative Reverse Proxy Synthesizer. Generates Nginx, Caddy, or IIS configurations
:: to map multi-vHost architectures to underlying WSGI ports and static webroots.
::
:: ## Usage
::   call provision_proxy.cmd --proxy <nginx|caddy|iis> --app-dir <dir> --packaging <path>

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "PROXY_TYPE="
set "APP_DIR="
set "PACKAGING_PATH="

:parse_args
if "%~1"=="" goto run_provision
if "%~1"=="--proxy" ( set "PROXY_TYPE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--app-dir" ( set "APP_DIR=%~2" & shift & shift & goto parse_args )
if "%~1"=="--packaging" ( set "PACKAGING_PATH=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:run_provision
if "%PROXY_TYPE%"=="" ( echo Error: Missing proxy >&2 & exit /b 1 )
if "%APP_DIR%"=="" ( echo Error: Missing app-dir >&2 & exit /b 1 )
if "%PACKAGING_PATH%"=="" ( echo Error: Missing packaging >&2 & exit /b 1 )

set "CONF_DIR=%APP_DIR%\proxy"
if not exist "%CONF_DIR%" mkdir "%CONF_DIR%"

if "%PROXY_TYPE%"=="nginx" goto do_nginx
if "%PROXY_TYPE%"=="caddy" goto do_caddy
if "%PROXY_TYPE%"=="iis" goto do_iis
echo Error: Unsupported proxy type "%PROXY_TYPE%" >&2
exit /b 1

:do_nginx
set "CONF_FILE=%CONF_DIR%\nginx.conf"
echo # Auto-generated Nginx Config > "%CONF_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; if (Get-Command 'jq' -ErrorAction SilentlyContinue) { $svcs = (jq -c '.services[]?' '%PACKAGING_PATH%'); foreach ($svc in $svcs) { $id = ($svc | jq -r '.id'); $type = ($svc | jq -r '.type'); if ($type -eq 'wsgi' -or $type -eq 'asgi') { $port = ($svc | jq -r '.port_binding'); Add-Content -Path '%CONF_FILE%' -Value \"server {`n    listen 80;`n    server_name ${id}.local;`n    location / {`n        proxy_pass http://127.0.0.1:${port};`n    }`n}\" } } }"
exit /b 0

:do_caddy
set "CONF_FILE=%CONF_DIR%\Caddyfile"
echo # Auto-generated Caddyfile > "%CONF_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; if (Get-Command 'jq' -ErrorAction SilentlyContinue) { $svcs = (jq -c '.services[]?' '%PACKAGING_PATH%'); foreach ($svc in $svcs) { $id = ($svc | jq -r '.id'); $type = ($svc | jq -r '.type'); if ($type -eq 'wsgi' -or $type -eq 'asgi') { $port = ($svc | jq -r '.port_binding'); Add-Content -Path '%CONF_FILE%' -Value \"${id}.local {`n    reverse_proxy 127.0.0.1:${port}`n}\" } } }"
exit /b 0

:do_iis
set "CONF_FILE=%CONF_DIR%\Web.config"
echo ^<?xml version="1.0" encoding="UTF-8"?^> > "%CONF_FILE%"
echo ^<!-- Auto-generated IIS Web.config --^> >> "%CONF_FILE%"
echo ^<configuration^> >> "%CONF_FILE%"
echo   ^<system.webServer^> >> "%CONF_FILE%"
echo     ^<rewrite^> >> "%CONF_FILE%"
echo       ^<rules^> >> "%CONF_FILE%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Continue'; if (Get-Command 'jq' -ErrorAction SilentlyContinue) { $svcs = (jq -c '.services[]?' '%PACKAGING_PATH%'); foreach ($svc in $svcs) { $id = ($svc | jq -r '.id'); $type = ($svc | jq -r '.type'); if ($type -eq 'wsgi' -or $type -eq 'asgi') { $port = ($svc | jq -r '.port_binding'); Add-Content -Path '%CONF_FILE%' -Value \"        <rule name=`\"ReverseProxyInbound_${id}`\" stopProcessing=`\"true`\">\n          <match url=`\"(.*)`\" />\n          <conditions>\n            <add input=`\"{HTTP_HOST}`\" pattern=`\"^${id}\.local$`\" />\n          </conditions>\n          <action type=`\"Rewrite`\" url=`\"http://127.0.0.1:${port}/{R:1}`\" />\n        </rule>\" } } }"
echo       ^</rules^> >> "%CONF_FILE%"
echo     ^</rewrite^> >> "%CONF_FILE%"
echo   ^</system.webServer^> >> "%CONF_FILE%"
echo ^</configuration^> >> "%CONF_FILE%"
exit /b 0