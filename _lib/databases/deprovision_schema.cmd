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

:: ## Overview
:: Safely deprovisions a multi-tenant database schema and user account on Windows.
:: Supports MySQL/MariaDB, PostgreSQL, MongoDB.
::
:: ## Usage
::   call deprovision_schema.cmd --engine <engine> --host <host> --port <port> --admin-user <user> --admin-pass <pass> --schema <name> --user <tenant>

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop
:found_root

set "ENGINE="
set "HOST=127.0.0.1"
set "PORT="
set "ADMIN_USER="
set "ADMIN_PASS="
set "SCHEMA_NAME="
set "TENANT_USER="

:parse_args
if "%~1"=="" goto run_deprovision
if "%~1"=="--engine" ( set "ENGINE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--host" ( set "HOST=%~2" & shift & shift & goto parse_args )
if "%~1"=="--port" ( set "PORT=%~2" & shift & shift & goto parse_args )
if "%~1"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_args )
if "%~1"=="--admin-pass" ( set "ADMIN_PASS=%~2" & shift & shift & goto parse_args )
if "%~1"=="--schema" ( set "SCHEMA_NAME=%~2" & shift & shift & goto parse_args )
if "%~1"=="--user" ( set "TENANT_USER=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:run_deprovision
if "%ENGINE%"=="" ( echo Error: Missing engine >&2 & exit /b 1 )
if "%SCHEMA_NAME%"=="" ( echo Error: Missing schema >&2 & exit /b 1 )
if "%TENANT_USER%"=="" ( echo Error: Missing tenant user >&2 & exit /b 1 )

if "%ENGINE%"=="mysql" goto do_mysql
if "%ENGINE%"=="mariadb" goto do_mysql
if "%ENGINE%"=="postgres" goto do_postgres
if "%ENGINE%"=="postgresql" goto do_postgres
if "%ENGINE%"=="mongodb" goto do_mongodb
if "%ENGINE%"=="sqlite" goto do_sqlite
echo Error: Unsupported engine "%ENGINE%" >&2
exit /b 1

:do_mysql
if "%PORT%"=="" set "PORT=3306"
if "%ADMIN_USER%"=="" set "ADMIN_USER=root"
set "TMP_SQL=%TEMP%\deprovision_!RANDOM!.sql"
echo DROP DATABASE IF EXISTS `%SCHEMA_NAME%`; > "%TMP_SQL%"
echo DROP USER IF EXISTS '%TENANT_USER%'@'localhost'; >> "%TMP_SQL%"
echo DROP USER IF EXISTS '%TENANT_USER%'@'127.0.0.1'; >> "%TMP_SQL%"
echo DROP USER IF EXISTS '%TENANT_USER%'@'%%'; >> "%TMP_SQL%"
echo FLUSH PRIVILEGES; >> "%TMP_SQL%"
if "%ADMIN_PASS%"=="" (
    mysql -h "%HOST%" -P "%PORT%" -u "%ADMIN_USER%" < "%TMP_SQL%"
) else (
    mysql -h "%HOST%" -P "%PORT%" -u "%ADMIN_USER%" -p"%ADMIN_PASS%" < "%TMP_SQL%"
)
del "%TMP_SQL%"
exit /b 0

:do_postgres
if "%PORT%"=="" set "PORT=5432"
if "%ADMIN_USER%"=="" set "ADMIN_USER=postgres"
set "PGPASSWORD=%ADMIN_PASS%"
psql -h "%HOST%" -p "%PORT%" -U "%ADMIN_USER%" -c "DROP DATABASE IF EXISTS \"%SCHEMA_NAME%\";"
psql -h "%HOST%" -p "%PORT%" -U "%ADMIN_USER%" -c "DROP USER IF EXISTS \"%TENANT_USER%\";"
set "PGPASSWORD="
exit /b 0

:do_mongodb
if "%PORT%"=="" set "PORT=27017"
set "MONGO_ARGS=--host %HOST% --port %PORT%"
if not "%ADMIN_USER%"=="" set "MONGO_ARGS=%MONGO_ARGS% -u %ADMIN_USER% -p %ADMIN_PASS% --authenticationDatabase admin"
set "JS_CMD=db.getSiblingDB('%SCHEMA_NAME%').dropDatabase(); db.getSiblingDB('%SCHEMA_NAME%').dropUser('%TENANT_USER%');"
mongosh %MONGO_ARGS% --eval "%JS_CMD%" --quiet
exit /b 0

:do_sqlite
if exist "%SCHEMA_NAME%" del /Q "%SCHEMA_NAME%" "%SCHEMA_NAME%-wal" "%SCHEMA_NAME%-shm"
exit /b 0