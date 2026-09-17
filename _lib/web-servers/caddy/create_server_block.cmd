@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # create_server_block.cmd
::
:: ## Overview
:: Generates a Caddy server block configuration on Windows.
::
:: ## Usage
:: Set ENV_SCRIPT_FILE and execute create_server_block.cmd.

if not "%ENV_SCRIPT_FILE%"=="" (
    if exist "%ENV_SCRIPT_FILE%" call "%ENV_SCRIPT_FILE%"
)

if "%SERVER_NAME%"=="" set "SERVER_NAME=localhost"
if "%LISTEN%"=="" set "LISTEN=80"
if "%WWWROOT%"=="" set "WWWROOT=C:\caddy\www"

echo :%LISTEN% {
echo     root * "%WWWROOT%"
if not "%CADDY_PHP_FPM_LISTEN%"=="" (
    echo     php_fastcgi %CADDY_PHP_FPM_LISTEN%
)
echo     file_server
echo }
exit /b 0
