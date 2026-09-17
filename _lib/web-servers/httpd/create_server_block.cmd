@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # create_server_block.cmd
::
:: ## Overview
:: Generates an Apache HTTPD VirtualHost block configuration on Windows.
::
:: ## Usage
:: Set ENV_SCRIPT_FILE and execute create_server_block.cmd.

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
