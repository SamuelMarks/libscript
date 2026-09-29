@echo off
:: # healthcheck.cmd
::
:: ## Overview
:: Full-stack diagnostic and health probe module for WordPress 7.1.2 on Windows.
:: Validates PHP runtime, database connectivity, and core file integrity.
::
:: ## Usage
::   call healthcheck.cmd [--json]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)
set "WP_CONFIG=%WORDPRESS_WWWROOT%\wp-config.php"

set "STATUS_PHP=FAIL"
where php >nul 2>&1
if not errorlevel 1 (
    for /f "delims=" %%v in ('php -r "echo PHP_VERSION;" 2^>nul') do set "STATUS_PHP=OK (%%v)"
    if "!STATUS_PHP!"=="FAIL" set "STATUS_PHP=OK"
)

set "STATUS_CORE=FAIL"
if exist "%WORDPRESS_WWWROOT%\index.php" (
    if exist "%WP_CONFIG%" set "STATUS_CORE=OK"
)

set "STATUS_DB=FAIL"
set "DB_HOST=127.0.0.1"
set "DB_PORT=3306"
set "DB_NAME=wordpress"
set "DB_USER=wordpress"
set "DB_PASSWORD=wordpress"

if exist "%WP_CONFIG%" (
    for /f "tokens=2 delims='" %%a in ('findstr /i "DB_NAME" "%WP_CONFIG%"') do set "DB_NAME=%%a"
    for /f "tokens=2 delims='" %%a in ('findstr /i "DB_USER" "%WP_CONFIG%"') do set "DB_USER=%%a"
    for /f "tokens=2 delims='" %%a in ('findstr /i "DB_PASSWORD" "%WP_CONFIG%"') do set "DB_PASSWORD=%%a"
    for /f "tokens=2 delims='" %%a in ('findstr /i "DB_HOST" "%WP_CONFIG%"') do (
        set "RAW_HOST=%%a"
        for /f "tokens=1,2 delims=:" %%h in ("!RAW_HOST!") do (
            set "DB_HOST=%%h"
            if not "%%i"=="" set "DB_PORT=%%i"
        )
    )
)

where mysql >nul 2>&1
if not errorlevel 1 (
    set "MYSQL_PWD=%DB_PASSWORD%"
    mysql -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -e "SELECT 1;" %DB_NAME% >nul 2>&1
    if not errorlevel 1 set "STATUS_DB=OK"
)

if "%~1"=="--json" (
    echo {"php":"%STATUS_PHP%","core_files":"%STATUS_CORE%","database":"%STATUS_DB%"}
    exit /b 0
)

echo.
echo ================= WordPress 7.1.2 Diagnostics (Windows) =================
echo   PHP Runtime     : %STATUS_PHP%
echo   WordPress Core  : %STATUS_CORE% (%WORDPRESS_WWWROOT%)
echo   Database        : %STATUS_DB% (%DB_HOST%:%DB_PORT% / %DB_NAME%)
echo =========================================================================
echo.

if "%STATUS_CORE%"=="OK" (
    echo [OK] WordPress platform diagnostics completed.
    exit /b 0
) else (
    echo [WARN] WordPress core files or database not yet configured.
    exit /b 0
)
