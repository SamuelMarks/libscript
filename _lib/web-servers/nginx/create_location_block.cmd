@echo off
:: # create_location_block.cmd
::
:: ## Overview
:: Lifecycle script for create_location_block.cmd.
::
:: ## Usage
:: Refer to the internal functions of create_location_block.cmd for implementation details.

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

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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
