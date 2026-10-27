@echo off
:: # create_server_block.cmd
::
:: ## Overview
:: Lifecycle script for create_server_block.cmd.
::
:: ## Usage
:: Refer to the internal functions of create_server_block.cmd for implementation details.

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


if not "%ENV_SCRIPT_FILE%"=="" (
    if exist "%ENV_SCRIPT_FILE%" call "%ENV_SCRIPT_FILE%"
)

if "%SERVER_NAME%"=="" set "SERVER_NAME=localhost"
if "%LISTEN%"=="" set "LISTEN=80"
if "%WWWROOT%"=="" set "WWWROOT=C:\Apache24\htdocs"

echo ^<VirtualHost *:%LISTEN%^>
echo     ServerName %SERVER_NAME%
echo     DocumentRoot "%WWWROOT%"
echo     ^<Directory "%WWWROOT%"^>
echo         Options Indexes FollowSymLinks
echo         AllowOverride All
echo         Require all granted
echo     ^</Directory^>
if not "%HTTPD_PHP_FPM_LISTEN%"=="" (
    echo     ^<FilesMatch \.php$^>
    echo         SetHandler "proxy:fcgi://%HTTPD_PHP_FPM_LISTEN%"
    echo     ^</FilesMatch^>
)
echo ^</VirtualHost^>
exit /b 0
