@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # create_location_block.cmd
::
:: ## Overview
:: Generates an Nginx location block configuration on Windows.
::
:: ## Usage
:: Set ENV_SCRIPT_FILE and execute create_location_block.cmd.

if not "%ENV_SCRIPT_FILE%"=="" (
    if exist "%ENV_SCRIPT_FILE%" call "%ENV_SCRIPT_FILE%"
)

if "%NGINX_LOCATION_EXPR%"=="" set "NGINX_LOCATION_EXPR=/"
if "%NGINX_WWWROOT%"=="" set "NGINX_WWWROOT=%WWWROOT%"

if not "%NGINX_PHP_FPM_LISTEN%"=="" (
    echo     location %NGINX_LOCATION_EXPR% {
    echo         root %NGINX_WWWROOT%;
    echo         index index.php index.html index.htm;
    echo         try_files $uri $uri/ /index.php$is_args$args;
    echo     }
    echo.
    echo     location ~ \.php$ {
    echo         root %NGINX_WWWROOT%;
    echo         include fastcgi_params;
    echo         fastcgi_pass %NGINX_PHP_FPM_LISTEN%;
    echo         fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;
    echo     }
) else if not "%PROXY_PASS%"=="" (
    echo     location %NGINX_LOCATION_EXPR% {
    echo         proxy_pass %PROXY_PASS%;
    echo         proxy_set_header Host $host;
    echo         proxy_set_header X-Real-IP $remote_addr;
    echo         proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    echo         proxy_set_header X-Forwarded-Proto $scheme;
    echo     }
) else (
    echo     location %NGINX_LOCATION_EXPR% {
    echo         root %NGINX_WWWROOT%;
    echo         index index.html index.htm;
    echo     }
)
exit /b 0
