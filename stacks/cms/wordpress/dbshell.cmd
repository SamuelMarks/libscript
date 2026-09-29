@echo off
:: # dbshell.cmd
::
:: ## Overview
:: Database console and query execution tool for WordPress 7.1.2 on Windows.
:: Reads connection parameters from wp-config.php and launches interactive MySQL
:: shell or executes queries, exports, and imports.
::
:: ## Usage
::   call dbshell.cmd [query <sql>|export <file.sql>|import <file.sql>|help]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%WORDPRESS_WWWROOT%"=="" (
    if defined ProgramFiles set "WORDPRESS_WWWROOT=%ProgramFiles%\WordPress\www"
    if not defined ProgramFiles set "WORDPRESS_WWWROOT=C:\WordPress\www"
)
set "WP_CONFIG=%WORDPRESS_WWWROOT%\wp-config.php"

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

set "CLIENT=mysql"
where mysql >nul 2>&1 || set "CLIENT=mariadb"
where %CLIENT% >nul 2>&1
if errorlevel 1 (
    echo [ERROR] Neither mysql nor mariadb client executable found in PATH. >&2
    exit /b 1
)

set "MYSQL_PWD=%DB_PASSWORD%"

set "CMD=%~1"
if "%CMD%"=="" goto do_interactive
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help
if "%CMD%"=="query" goto do_query
if "%CMD%"=="sql" goto do_query
if "%CMD%"=="export" goto do_export
if "%CMD%"=="import" goto do_import

:: Treat arguments as raw query or parameters
%CLIENT% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% %DB_NAME% %*
exit /b %ERRORLEVEL%

:do_interactive
%CLIENT% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% %DB_NAME%
exit /b %ERRORLEVEL%

:do_query
shift
%CLIENT% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% -e "%~1" %DB_NAME%
exit /b %ERRORLEVEL%

:do_export
shift
set "OUT_FILE=%~1"
if "%OUT_FILE%"=="" set "OUT_FILE=wordpress_dump.sql"
mysqldump -h %DB_HOST% -P %DB_PORT% -u %DB_USER% --single-transaction --quick %DB_NAME% > "%OUT_FILE%"
echo [OK] WordPress database exported to %OUT_FILE%
exit /b %ERRORLEVEL%

:do_import
shift
set "IN_FILE=%~1"
if "%IN_FILE%"=="" (
    echo [ERROR] Usage: dbshell.cmd import ^<file.sql^> >&2
    exit /b 1
)
%CLIENT% -h %DB_HOST% -P %DB_PORT% -u %DB_USER% %DB_NAME% < "%IN_FILE%"
echo [OK] WordPress database imported from %IN_FILE%
exit /b %ERRORLEVEL%

:show_help
echo WordPress Database Console on Windows
echo.
echo Usage:
echo   call dbshell.cmd                    Launch interactive database shell
echo   call dbshell.cmd query "^<sql^>"      Execute SQL query
echo   call dbshell.cmd export [file.sql]  Export database dump
echo   call dbshell.cmd import ^<file.sql^>  Import database dump
exit /b 0
