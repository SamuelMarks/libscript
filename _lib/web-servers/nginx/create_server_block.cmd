@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # create_server_block.cmd
::
:: ## Overview
:: Generates an Nginx server block configuration on Windows.
::
:: ## Usage
:: Set ENV_SCRIPT_FILE and execute create_server_block.cmd.

if not "%ENV_SCRIPT_FILE%"=="" (
    if exist "%ENV_SCRIPT_FILE%" call "%ENV_SCRIPT_FILE%"
)

if "%NGINX_SERVER_NAME%"=="" set "NGINX_SERVER_NAME=%SERVER_NAME%"
if "%NGINX_SERVER_NAME%"=="" set "NGINX_SERVER_NAME=localhost"

if "%NGINX_LISTEN%"=="" set "NGINX_LISTEN=%LISTEN%"
if "%NGINX_LISTEN%"=="" set "NGINX_LISTEN=80"

echo map $http_upgrade $connection_upgrade {
echo     default upgrade;
echo     ''      close;
echo }
echo.
echo server {
echo     server_name %NGINX_SERVER_NAME%;
echo     listen %NGINX_LISTEN%;
echo.
if not "%LOCATIONS%"=="" (
    echo %LOCATIONS%
)
echo }
exit /b 0
