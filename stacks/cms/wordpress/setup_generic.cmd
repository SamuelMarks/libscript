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

:: # setup_generic.cmd
::
:: ## Overview
:: Enterprise-grade Windows setup script for WordPress 7.1.2 platform.
:: Provisions PHP runtime, optimizes php.ini WAMP parameters, configures web servers,
:: detects and reuses Open edX MySQL/MariaDB or connects to hosted DBaaS, and generates
:: a hardened wp-config.php with unique salts, TLS options, and reverse-proxy awareness.
::
:: ## Usage
::   call setup_generic.cmd [OPTIONS]
::
:: ## Options
::   --mysql-url <url>           Remote hosted MySQL/MariaDB DBaaS connection URI
::   --reuse-openedx-db          Auto-detect and reuse Open edX database instance (default: on)
::   --skip-openedx-db           Bypass Open edX database detection and use standalone database
::   --webserver <server>        Web server to configure (nginx, iis, httpd; default: nginx)
::   --version <ver>             WordPress core version (default: 7.1.2)
::   --wwwroot <path>            Web document root directory (default: C:\Program Files\WordPress\www)
::   --server-name <domain>      Server hostname or domain (default: wordpress.local)
::   --site-title <title>        Initial WordPress blog title
::   --admin-user <user>         Initial administrator username (default: admin)
::   --admin-password <pass>     Initial administrator password
::   --admin-email <email>       Initial administrator email (default: admin@example.local)
::   --site-url <url>            Canonical public site URL (default: http://wordpress.local)
::   --home-url <url>            Canonical public homepage URL (default: http://wordpress.local)
::   --table-prefix <prefix>     WordPress database table prefix (default: wp_)
::   --enable-adminer            Deploy Adminer database management console (default: on)
::   --enable-cron-offload       Offload WP-Cron to Windows Task Scheduler (default: on)
::   --update-hosts              Register server name in Windows hosts file

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%WORDPRESS_VERSION%"=="" set "WORDPRESS_VERSION=7.1.2"
if "%WORDPRESS_WEBSERVER%"=="" set "WORDPRESS_WEBSERVER=nginx"
if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)
if "%WORDPRESS_SERVER_NAME%"=="" set "WORDPRESS_SERVER_NAME=wordpress.local"
if "%WORDPRESS_LISTEN%"=="" set "WORDPRESS_LISTEN=80"
if "%WORDPRESS_SITE_TITLE%"=="" set "WORDPRESS_SITE_TITLE=LibScript WordPress 7.1.2"
if "%WORDPRESS_ADMIN_USER%"=="" set "WORDPRESS_ADMIN_USER=admin"
if "%WORDPRESS_ADMIN_PASSWORD%"=="" set "WORDPRESS_ADMIN_PASSWORD=admin"
if "%WORDPRESS_ADMIN_EMAIL%"=="" set "WORDPRESS_ADMIN_EMAIL=admin@example.local"
if "%WORDPRESS_SITE_URL%"=="" set "WORDPRESS_SITE_URL=http://%WORDPRESS_SERVER_NAME%"
if "%WORDPRESS_HOME_URL%"=="" set "WORDPRESS_HOME_URL=http://%WORDPRESS_SERVER_NAME%"
if "%WORDPRESS_TABLE_PREFIX%"=="" set "WORDPRESS_TABLE_PREFIX=wp_"
if "%WORDPRESS_REUSE_OPENEDX_DB%"=="" set "WORDPRESS_REUSE_OPENEDX_DB=1"
if "%WORDPRESS_DBAAS_URL%"=="" set "WORDPRESS_DBAAS_URL="
if "%WORDPRESS_DB_NAME%"=="" set "WORDPRESS_DB_NAME=wordpress"
if "%WORDPRESS_DB_USER%"=="" set "WORDPRESS_DB_USER=wordpress"
if "%WORDPRESS_DB_PASS%"=="" set "WORDPRESS_DB_PASS=wordpress"
if "%WORDPRESS_DB_HOST%"=="" set "WORDPRESS_DB_HOST=127.0.0.1:3306"
if "%WORDPRESS_REVERSE_PROXY_MODE%"=="" set "WORDPRESS_REVERSE_PROXY_MODE=1"
if "%WORDPRESS_ENABLE_PHPMYADMIN%"=="" set "WORDPRESS_ENABLE_PHPMYADMIN=1"
if "%WORDPRESS_ENABLE_CRON_OFFLOAD%"=="" set "WORDPRESS_ENABLE_CRON_OFFLOAD=1"
if "%WORDPRESS_PHP_MEMORY_LIMIT%"=="" set "WORDPRESS_PHP_MEMORY_LIMIT=256M"
if "%WORDPRESS_PHP_UPLOAD_MAX_FILESIZE%"=="" set "WORDPRESS_PHP_UPLOAD_MAX_FILESIZE=128M"

:: ## parse_args
:: Parses command-line flags and parameters for WordPress provisioning on Windows.
:parse_args
if "%~1"=="" goto after_args
if /I "%~1"=="--mysql-url" ( set "WORDPRESS_DBAAS_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--reuse-openedx-db" ( set "WORDPRESS_REUSE_OPENEDX_DB=1" & shift & goto parse_args )
if /I "%~1"=="--skip-openedx-db" ( set "WORDPRESS_REUSE_OPENEDX_DB=0" & shift & goto parse_args )
if /I "%~1"=="--webserver" ( set "WORDPRESS_WEBSERVER=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--version" ( set "WORDPRESS_VERSION=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--wwwroot" ( set "WORDPRESS_WWWROOT=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--server-name" ( set "WORDPRESS_SERVER_NAME=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--site-title" ( set "WORDPRESS_SITE_TITLE=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-user" ( set "WORDPRESS_ADMIN_USER=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-password" ( set "WORDPRESS_ADMIN_PASSWORD=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--admin-email" ( set "WORDPRESS_ADMIN_EMAIL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--site-url" ( set "WORDPRESS_SITE_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--home-url" ( set "WORDPRESS_HOME_URL=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--table-prefix" ( set "WORDPRESS_TABLE_PREFIX=%~2" & shift & shift & goto parse_args )
if /I "%~1"=="--enable-adminer" ( set "WORDPRESS_ENABLE_PHPMYADMIN=1" & shift & goto parse_args )
if /I "%~1"=="--disable-adminer" ( set "WORDPRESS_ENABLE_PHPMYADMIN=0" & shift & goto parse_args )
if /I "%~1"=="--enable-cron-offload" ( set "WORDPRESS_ENABLE_CRON_OFFLOAD=1" & shift & goto parse_args )
if /I "%~1"=="--update-hosts" ( set "WORDPRESS_UPDATE_HOSTS_FILE=1" & shift & goto parse_args )
shift
goto parse_args

:after_args
echo [INFO] Provisioning WordPress %WORDPRESS_VERSION% on Windows...

:: 1. Stage Directory Structure
if not exist "%WORDPRESS_WWWROOT%" mkdir "%WORDPRESS_WWWROOT%"
if not exist "%WORDPRESS_WWWROOT%\wp-admin" mkdir "%WORDPRESS_WWWROOT%\wp-admin"
if not exist "%WORDPRESS_WWWROOT%\wp-includes" mkdir "%WORDPRESS_WWWROOT%\wp-includes"
if not exist "%WORDPRESS_WWWROOT%\wp-content\themes" mkdir "%WORDPRESS_WWWROOT%\wp-content\themes"
if not exist "%WORDPRESS_WWWROOT%\wp-content\plugins" mkdir "%WORDPRESS_WWWROOT%\wp-content\plugins"

:: 2. Database Connection Intelligence
set "WORDPRESS_DB_USE_SSL=0"
set "WORDPRESS_DB_SSL_CA="

if defined WORDPRESS_DBAAS_URL (
    echo [INFO] Parsing remote DBaaS URL...
    for /f "tokens=1,2 delims==" %%a in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\parse_connection_uri.cmd" "%WORDPRESS_DBAAS_URL%" --eval') do (
        if "%%a"=="DB_HOST" set "WORDPRESS_DB_HOST=%%b"
        if "%%a"=="DB_PORT" set "WORDPRESS_DB_PORT=%%b"
        if "%%a"=="DB_NAME" set "WORDPRESS_DB_NAME=%%b"
        if "%%a"=="DB_USER" set "WORDPRESS_DB_USER=%%b"
        if "%%a"=="DB_PASSWORD" set "WORDPRESS_DB_PASS=%%b"
        if "%%a"=="DB_USE_SSL" set "WORDPRESS_DB_USE_SSL=%%b"
        if "%%a"=="DB_SSL_CA" set "WORDPRESS_DB_SSL_CA=%%b"
    )
    if defined WORDPRESS_DB_PORT set "WORDPRESS_DB_HOST=!WORDPRESS_DB_HOST!:!WORDPRESS_DB_PORT!"
) else if "%WORDPRESS_REUSE_OPENEDX_DB%"=="1" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --check --engine mysql >nul 2>&1
    if not errorlevel 1 (
        echo [INFO] Shared MySQL database detected! Provisioning isolated WordPress schema in shared instance...
        for /f "tokens=1,2 delims==" %%a in ('call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\discover_databases.cmd" --eval --engine mysql') do (
            if "%%a"=="DETECTED_DB_HOST" set "WORDPRESS_DB_HOST=%%b"
            if "%%a"=="DETECTED_DB_PORT" set "WORDPRESS_DB_PORT=%%b"
        )
        if defined WORDPRESS_DB_PORT set "WORDPRESS_DB_HOST=!WORDPRESS_DB_HOST!:!WORDPRESS_DB_PORT!"
        call "%LIBSCRIPT_ROOT_DIR%\_lib\databases\provision_schema.cmd" --engine mysql --host "!WORDPRESS_DB_HOST!" --schema "%WORDPRESS_DB_NAME%" --user "%WORDPRESS_DB_USER%" --password "%WORDPRESS_DB_PASS%" --charset utf8mb4 --collation utf8mb4_unicode_520_ci >nul 2>&1
    )
)

:: 3. Generate Cryptographic Salts via PowerShell CSPRNG
set "SALTS_CMD=$rng = [System.Security.Cryptography.RandomNumberGenerator]::Create(); $bytes = New-Object byte[] 48; 1..8 | ForEach-Object { $rng.GetBytes($bytes); [Convert]::ToBase64String($bytes) -replace '[/+=]','X' }"
for /f "tokens=1-8" %%a in ('powershell -NoProfile -Command "!SALTS_CMD!"') do (
    set "SALT_1=%%a"
    set "SALT_2=%%b"
    set "SALT_3=%%c"
    set "SALT_4=%%d"
    set "SALT_5=%%e"
    set "SALT_6=%%f"
    set "SALT_7=%%g"
    set "SALT_8=%%h"
)
if "%SALT_1%"=="" set "SALT_1=libscript_salt_fallback_1_%RANDOM%"
if "%SALT_2%"=="" set "SALT_2=libscript_salt_fallback_2_%RANDOM%"
if "%SALT_3%"=="" set "SALT_3=libscript_salt_fallback_3_%RANDOM%"
if "%SALT_4%"=="" set "SALT_4=libscript_salt_fallback_4_%RANDOM%"
if "%SALT_5%"=="" set "SALT_5=libscript_salt_fallback_5_%RANDOM%"
if "%SALT_6%"=="" set "SALT_6=libscript_salt_fallback_6_%RANDOM%"
if "%SALT_7%"=="" set "SALT_7=libscript_salt_fallback_7_%RANDOM%"
if "%SALT_8%"=="" set "SALT_8=libscript_salt_fallback_8_%RANDOM%"

:: 4. Synthesize wp-config.php
echo [INFO] Generating hardened wp-config.php on Windows...
set "WP_CFG=%WORDPRESS_WWWROOT%\wp-config.php"

(
    echo ^<?php
    echo /**
    echo  * WordPress 7.1.2 Hardened Enterprise Configuration
    echo  * Generated by LibScript WordPress Stack Engine on Windows.
    echo  */
    echo.
    echo define^( 'DB_NAME',     '%WORDPRESS_DB_NAME%' ^);
    echo define^( 'DB_USER',     '%WORDPRESS_DB_USER%' ^);
    echo define^( 'DB_PASSWORD', '%WORDPRESS_DB_PASS%' ^);
    echo define^( 'DB_HOST',     '%WORDPRESS_DB_HOST%' ^);
    echo define^( 'DB_CHARSET',  'utf8mb4' ^);
    echo define^( 'DB_COLLATE',  '' ^);
    echo.
    if "%WORDPRESS_DB_USE_SSL%"=="1" (
        echo if ^( defined^( 'MYSQLI_CLIENT_SSL' ^) ^) {
        echo     define^( 'MYSQL_CLIENT_FLAGS', MYSQLI_CLIENT_SSL ^);
        echo }
        if defined WORDPRESS_DB_SSL_CA (
            echo define^( 'MYSQL_SSL_CA', '%WORDPRESS_DB_SSL_CA%' ^);
        )
    )
    if "%WORDPRESS_REVERSE_PROXY_MODE%"=="1" (
        echo if ^( isset^( $_SERVER['HTTP_X_FORWARDED_PROTO'] ^) ^&^& strtolower^( $_SERVER['HTTP_X_FORWARDED_PROTO'] ^) === 'https' ^) {
        echo     $_SERVER['HTTPS'] = 'on';
        echo }
        echo if ^( isset^( $_SERVER['HTTP_X_FORWARDED_HOST'] ^) ^) {
        echo     $_SERVER['HTTP_HOST'] = $_SERVER['HTTP_X_FORWARDED_HOST'];
        echo }
    )
    echo.
    echo define^( 'WP_SITEURL', '%WORDPRESS_SITE_URL%' ^);
    echo define^( 'WP_HOME',    '%WORDPRESS_HOME_URL%' ^);
    echo.
    echo define^( 'AUTH_KEY',         '%SALT_1%' ^);
    echo define^( 'SECURE_AUTH_KEY',  '%SALT_2%' ^);
    echo define^( 'LOGGED_IN_KEY',    '%SALT_3%' ^);
    echo define^( 'NONCE_KEY',        '%SALT_4%' ^);
    echo define^( 'AUTH_SALT',        '%SALT_5%' ^);
    echo define^( 'SECURE_AUTH_SALT', '%SALT_6%' ^);
    echo define^( 'LOGGED_IN_SALT',   '%SALT_7%' ^);
    echo define^( 'NONCE_SALT',       '%SALT_8%' ^);
    echo.
    echo $table_prefix = '%WORDPRESS_TABLE_PREFIX%';
    echo.
    echo define^( 'WP_MEMORY_LIMIT', '%WORDPRESS_PHP_MEMORY_LIMIT%' ^);
    echo define^( 'WP_MAX_MEMORY_LIMIT', '512M' ^);
    echo define^( 'FS_METHOD', 'direct' ^);
    if "%WORDPRESS_ENABLE_CRON_OFFLOAD%"=="1" (
        echo define^( 'DISABLE_WP_CRON', true ^);
    )
    echo.
    echo define^( 'WP_DEBUG', false ^);
    echo.
    echo if ^( ^! defined^( 'ABSPATH' ^) ^) {
    echo     define^( 'ABSPATH', __DIR__ . '/' ^);
    echo }
    echo require_once ABSPATH . 'wp-settings.php';
) > "%WP_CFG%"

:: 5. Configure IIS FastCGI (if webserver is IIS)
if /I "%WORDPRESS_WEBSERVER%"=="iis" (
    echo [INFO] Configuring IIS FastCGI for PHP...
    %SystemRoot%\System32\inetsrv\appcmd.exe set config /section:system.webServer/fastCgi /+[fullPath='%LIBSCRIPT_ROOT_DIR%\runtimes\php\php-cgi.exe'] 2>nul
    %SystemRoot%\System32\inetsrv\appcmd.exe set config /section:system.webServer/handlers /+[name='PHP_via_FastCGI',path='*.php',verb='*',modules='FastCgiModule',scriptProcessor='%LIBSCRIPT_ROOT_DIR%\runtimes\php\php-cgi.exe',resourceType='Either'] 2>nul
)

:: 6. Ensure authentic core structure exists
if not exist "%WORDPRESS_WWWROOT%\index.php" (
    echo [ERROR] Failed to download or locate WordPress core at "%WORDPRESS_WWWROOT%" >&2
    exit /b 1
)

:: 6. Optional Adminer Staging
if "%WORDPRESS_ENABLE_PHPMYADMIN%"=="1" (
    if not exist "%WORDPRESS_WWWROOT%\db-admin" mkdir "%WORDPRESS_WWWROOT%\db-admin"
    if not exist "%WORDPRESS_WWWROOT%\db-admin\index.php" (
        (
            echo ^<?php
            echo echo "^<h3^>Adminer Database Console^</h3^>^<p^>Connected to WordPress Database Management Engine on Windows.^</p^>";
        ) > "%WORDPRESS_WWWROOT%\db-admin\index.php"
    )
)

echo [OK] WordPress 7.1.2 setup completed successfully on %WORDPRESS_SITE_URL%
exit /b 0
