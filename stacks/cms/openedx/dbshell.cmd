@echo off
:: # dbshell.cmd
::
:: ## Overview
:: Database console and query execution wrapper for Open edX on Windows.
:: Provides unified CLI access to MySQL, MongoDB, and Redis datastores.
::
:: ## Usage
::   call dbshell.cmd mysql [optional_mysql_args...]
::   call dbshell.cmd mongo [optional_mongo_args...]
::   call dbshell.cmd redis [optional_redis_args...]
::   call dbshell.cmd query <sql_statement>
::   call dbshell.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Client invocation failure or missing database client binary

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

if "%MYSQL_HOST%"=="" set "MYSQL_HOST=127.0.0.1"
if "%MYSQL_PORT%"=="" set "MYSQL_PORT=3306"
if "%MYSQL_USER%"=="" set "MYSQL_USER=openedx"
if "%MYSQL_DATABASE%"=="" set "MYSQL_DATABASE=openedx"

if "%MONGODB_HOST%"=="" set "MONGODB_HOST=127.0.0.1"
if "%MONGODB_PORT%"=="" set "MONGODB_PORT=27017"
if "%MONGODB_DATABASE%"=="" set "MONGODB_DATABASE=openedx"

if "%REDIS_HOST%"=="" set "REDIS_HOST=127.0.0.1"
if "%REDIS_PORT%"=="" set "REDIS_PORT=6379"

set "CONFIG_JSON=%OPENEDX_INSTALL_DIR%\config\lms.env.json"
if exist "%CONFIG_JSON%" (
    where powershell >nul 2>nul
    if not errorlevel 1 (
        for /f "tokens=1,2 delims==" %%a in ('powershell -NoProfile -Command "$raw = Get-Content -Raw '%CONFIG_JSON%' -ErrorAction SilentlyContinue; if ($raw) { try { $cfg = (ConvertFrom-Json $raw).DATABASES.default; if ($cfg.HOST) { \"MYSQL_HOST=$($cfg.HOST)\" }; if ($cfg.PORT) { \"MYSQL_PORT=$($cfg.PORT)\" }; if ($cfg.USER) { \"MYSQL_USER=$($cfg.USER)\" }; if ($cfg.NAME) { \"MYSQL_DATABASE=$($cfg.NAME)\" } } catch {} }"') do (
            set "%%a=%%b"
        )
    )
)

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="mysql" goto do_mysql
if "%CMD%"=="mongo" goto do_mongo
if "%CMD%"=="mongodb" goto do_mongo
if "%CMD%"=="mongosh" goto do_mongo
if "%CMD%"=="redis" goto do_redis
if "%CMD%"=="redis-cli" goto do_redis
if "%CMD%"=="query" goto do_query
if "%CMD%"=="sql" goto do_query

echo [ERROR] Unknown database command: %CMD% >&2
goto show_help

:: ## do_mysql
:: Connects to the MySQL database interactive shell.
:do_mysql
shift
where mysql >nul 2>nul
if not errorlevel 1 (
    if defined MYSQL_PASSWORD set "MYSQL_PWD=%MYSQL_PASSWORD%"
    mysql -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% %MYSQL_DATABASE% %*
    exit /b %errorlevel%
)
where mariadb >nul 2>nul
if not errorlevel 1 (
    if defined MYSQL_PASSWORD set "MYSQL_PWD=%MYSQL_PASSWORD%"
    mariadb -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% %MYSQL_DATABASE% %*
    exit /b %errorlevel%
)
echo [ERROR] Neither mysql nor mariadb executable found in PATH. >&2
exit /b 1

:: ## do_mongo
:: Connects to the MongoDB shell.
:do_mongo
shift
set "MONGO_URI=mongodb://%MONGODB_HOST%:%MONGODB_PORT%/%MONGODB_DATABASE%"
where mongosh >nul 2>nul
if not errorlevel 1 (
    mongosh "%MONGO_URI%" %*
    exit /b %errorlevel%
)
where mongo >nul 2>nul
if not errorlevel 1 (
    mongo "%MONGO_URI%" %*
    exit /b %errorlevel%
)
echo [ERROR] Neither mongosh nor mongo executable found in PATH. >&2
exit /b 1

:: ## do_redis
:: Connects to the Redis CLI interactive shell.
:do_redis
shift
where redis-cli >nul 2>nul
if not errorlevel 1 (
    redis-cli -h %REDIS_HOST% -p %REDIS_PORT% %*
    exit /b %errorlevel%
)
where valkey-cli >nul 2>nul
if not errorlevel 1 (
    valkey-cli -h %REDIS_HOST% -p %REDIS_PORT% %*
    exit /b %errorlevel%
)
echo [ERROR] Neither redis-cli nor valkey-cli executable found in PATH. >&2
exit /b 1

:: ## do_query
:: Executes a non-interactive SQL statement against MySQL.
:do_query
shift
set "SQL_QUERY=%~1"
if "%SQL_QUERY%"=="" (
    echo [ERROR] SQL query is required. >&2
    exit /b 1
)
where mysql >nul 2>nul
if not errorlevel 1 (
    if defined MYSQL_PASSWORD set "MYSQL_PWD=%MYSQL_PASSWORD%"
    mysql -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% -e "%SQL_QUERY%" %MYSQL_DATABASE%
    exit /b %errorlevel%
)
where mariadb >nul 2>nul
if not errorlevel 1 (
    if defined MYSQL_PASSWORD set "MYSQL_PWD=%MYSQL_PASSWORD%"
    mariadb -h %MYSQL_HOST% -P %MYSQL_PORT% -u %MYSQL_USER% -e "%SQL_QUERY%" %MYSQL_DATABASE%
    exit /b %errorlevel%
)
echo [ERROR] No MySQL client available to execute query. >&2
exit /b 1

:: ## show_help
:: Displays database console command usage.
:show_help
echo Open edX Database Console Wrapper (Windows)
echo.
echo Usage:
echo   call dbshell.cmd mysql [optional_args...]
echo   call dbshell.cmd mongo [optional_args...]
echo   call dbshell.cmd redis [optional_args...]
echo   call dbshell.cmd query ^<sql_statement^>
echo   call dbshell.cmd help
exit /b 0
