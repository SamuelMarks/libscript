@echo off
:: # provision_schema.cmd
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

:: ## Overview
:: Idempotently provisions a multi-tenant database schema and least-privilege user account on Windows.
:: Supports MySQL/MariaDB, PostgreSQL, MongoDB, and SQLite with reuse-else-create semantics.
::
:: ## Usage
::   call provision_schema.cmd --engine <engine> --host <host> --port <port> --admin-user <user> --admin-pass <pass> --schema <name> --user <tenant> --password <tenant_pass> [--legacy-names <csv>]

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

set "ENGINE="
set "HOST=127.0.0.1"
set "PORT="
set "ADMIN_USER="
set "ADMIN_PASS="
set "SCHEMA_NAME="
set "LEGACY_NAMES="
set "TENANT_USER="
set "TENANT_PASS="
set "CHARSET=utf8mb4"
set "COLLATION=utf8mb4_unicode_ci"

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto run_provision
if "%~1"=="--engine" ( set "ENGINE=%~2" & shift & shift & goto parse_args )
if "%~1"=="--host" ( set "HOST=%~2" & shift & shift & goto parse_args )
if "%~1"=="--port" ( set "PORT=%~2" & shift & shift & goto parse_args )
if "%~1"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto parse_args )
if "%~1"=="--admin-pass" ( set "ADMIN_PASS=%~2" & shift & shift & goto parse_args )
if "%~1"=="--schema" ( set "SCHEMA_NAME=%~2" & shift & shift & goto parse_args )
if "%~1"=="--legacy-names" ( set "LEGACY_NAMES=%~2" & shift & shift & goto parse_args )
if "%~1"=="--user" ( set "TENANT_USER=%~2" & shift & shift & goto parse_args )
if "%~1"=="--password" ( set "TENANT_PASS=%~2" & shift & shift & goto parse_args )
if "%~1"=="--charset" ( set "CHARSET=%~2" & shift & shift & goto parse_args )
if "%~1"=="--collation" ( set "COLLATION=%~2" & shift & shift & goto parse_args )
shift
goto parse_args

:: ## run_provision
:: Performs the run_provision operation and updates component state.
:run_provision
if "%ENGINE%"=="" ( echo Error: Missing engine >&2 & exit /b 1 )
if "%SCHEMA_NAME%"=="" ( echo Error: Missing schema >&2 & exit /b 1 )
if "%TENANT_USER%"=="" ( echo Error: Missing tenant user >&2 & exit /b 1 )
if "%TENANT_PASS%"=="" ( echo Error: Missing tenant pass >&2 & exit /b 1 )

if "%ENGINE%"=="mysql" goto do_mysql
if "%ENGINE%"=="mariadb" goto do_mysql
if "%ENGINE%"=="postgres" goto do_postgres
if "%ENGINE%"=="postgresql" goto do_postgres
if "%ENGINE%"=="mongodb" goto do_mongodb
if "%ENGINE%"=="sqlite" goto do_sqlite
echo Error: Unsupported engine "%ENGINE%" >&2
exit /b 1

:: ## do_mysql
:: Performs the do_mysql operation and updates component state.
:do_mysql
if "%PORT%"=="" set "PORT=3306"
if "%ADMIN_USER%"=="" set "ADMIN_USER=root"
set "TMP_SQL=%TEMP%\provision_!RANDOM!.sql"
echo CREATE DATABASE IF NOT EXISTS `%SCHEMA_NAME%` DEFAULT CHARACTER SET %CHARSET% COLLATE %COLLATION%; > "%TMP_SQL%"
echo CREATE USER IF NOT EXISTS '%TENANT_USER%'@'localhost' IDENTIFIED BY '%TENANT_PASS%'; >> "%TMP_SQL%"
echo CREATE USER IF NOT EXISTS '%TENANT_USER%'@'127.0.0.1' IDENTIFIED BY '%TENANT_PASS%'; >> "%TMP_SQL%"
echo CREATE USER IF NOT EXISTS '%TENANT_USER%'@'%%' IDENTIFIED BY '%TENANT_PASS%'; >> "%TMP_SQL%"
echo GRANT ALL PRIVILEGES ON `%SCHEMA_NAME%`.* TO '%TENANT_USER%'@'localhost'; >> "%TMP_SQL%"
echo GRANT ALL PRIVILEGES ON `%SCHEMA_NAME%`.* TO '%TENANT_USER%'@'127.0.0.1'; >> "%TMP_SQL%"
echo GRANT ALL PRIVILEGES ON `%SCHEMA_NAME%`.* TO '%TENANT_USER%'@'%%'; >> "%TMP_SQL%"
echo FLUSH PRIVILEGES; >> "%TMP_SQL%"
if "%ADMIN_PASS%"=="" (
    mysql -h "%HOST%" -P "%PORT%" -u "%ADMIN_USER%" < "%TMP_SQL%"
) else (
    mysql -h "%HOST%" -P "%PORT%" -u "%ADMIN_USER%" -p"%ADMIN_PASS%" < "%TMP_SQL%"
)
del "%TMP_SQL%"
exit /b 0

:: ## run_psql_admin
:: Executes a psql administrative command against the specified database on Windows.
:run_psql_admin
set "_RPA_DB=%~1"
set "_RPA_FLAG=%~2"
set "_RPA_SQL=%~3"
set "PGPASSWORD=%ADMIN_PASS%"
psql -h "%HOST%" -p "%PORT%" -U "%ADMIN_USER%" -d "%_RPA_DB%" %_RPA_FLAG% "%_RPA_SQL%" 2>nul
if not errorlevel 1 exit /b 0
set "PGPASSWORD=%TENANT_PASS%"
psql -h "%HOST%" -p "%PORT%" -U "%TENANT_USER%" -d "%_RPA_DB%" %_RPA_FLAG% "%_RPA_SQL%" 2>nul
exit /b !errorlevel!

:: ## do_postgres
:: Idempotently reuses or creates PostgreSQL role and database schema on Windows.
:do_postgres
if "%PORT%"=="" set "PORT=5432"
if "%ADMIN_USER%"=="" set "ADMIN_USER=postgres"
set "PGPASSWORD=%ADMIN_PASS%"
call :run_psql_admin postgres -tAc "SELECT 1 FROM pg_roles WHERE rolname='%TENANT_USER%'" | findstr "1" >nul
if not errorlevel 1 (
    set "PGPASSWORD=%TENANT_PASS%"
    psql -h "%HOST%" -p "%PORT%" -U "%TENANT_USER%" -d postgres -tAc "SELECT 1" >nul 2>&1
    if not errorlevel 1 (
        echo [REUSE] PostgreSQL role '%TENANT_USER%' already exists.
    ) else (
        echo [REUSE] PostgreSQL role '%TENANT_USER%' exists; synchronizing password...
        call :run_psql_admin postgres -c "ALTER USER \"%TENANT_USER%\" WITH LOGIN PASSWORD '%TENANT_PASS%';" >nul 2>&1
    )
) else (
    echo [CREATE] Creating PostgreSQL role '%TENANT_USER%'...
    call :run_psql_admin postgres -c "CREATE USER \"%TENANT_USER%\" WITH LOGIN ENCRYPTED PASSWORD '%TENANT_PASS%';" >nul 2>&1
)
call :run_psql_admin postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%SCHEMA_NAME%'" | findstr "1" >nul
if not errorlevel 1 (
    echo [REUSE] PostgreSQL database '%SCHEMA_NAME%' already exists.
) else (
    set "_MIGRATED_LEGACY=0"
    if not "!LEGACY_NAMES!"=="" (
        for %%L in (!LEGACY_NAMES!) do (
            if "!_MIGRATED_LEGACY!"=="0" if /i not "%%~L"=="%SCHEMA_NAME%" (
                call :run_psql_admin postgres -tAc "SELECT 1 FROM pg_database WHERE datname='%%~L'" | findstr "1" >nul
                if not errorlevel 1 (
                    echo [REUSE] Renaming legacy PostgreSQL database '%%~L' -^> '%SCHEMA_NAME%'...
                    call :run_psql_admin postgres -c "ALTER DATABASE \"%%~L\" RENAME TO \"%SCHEMA_NAME%\";" >nul 2>&1
                    if not errorlevel 1 set "_MIGRATED_LEGACY=1"
                )
            )
        )
    )
    if "!_MIGRATED_LEGACY!"=="0" (
        echo [CREATE] Creating PostgreSQL database '%SCHEMA_NAME%' owned by '%TENANT_USER%'...
        call :run_psql_admin postgres -c "CREATE DATABASE \"%SCHEMA_NAME%\" OWNER \"%TENANT_USER%\";" >nul 2>&1
    )
)
call :run_psql_admin postgres -c "GRANT ALL PRIVILEGES ON DATABASE \"%SCHEMA_NAME%\" TO \"%TENANT_USER%\";" >nul 2>&1
call :run_psql_admin "%SCHEMA_NAME%" -c "ALTER SCHEMA public OWNER TO \"%TENANT_USER%\";" >nul 2>&1
set "PGPASSWORD="
exit /b 0

:: ## do_mongodb
:: Performs the do_mongodb operation and updates component state.
:do_mongodb
if "%PORT%"=="" set "PORT=27017"
set "MONGO_ARGS=--host %HOST% --port %PORT%"
if not "%ADMIN_USER%"=="" set "MONGO_ARGS=%MONGO_ARGS% -u %ADMIN_USER% -p %ADMIN_PASS% --authenticationDatabase admin"
set "JS_CHECK=var res = db.getSiblingDB('%SCHEMA_NAME%').getUser('%TENANT_USER%'); if (!res) { db.getSiblingDB('%SCHEMA_NAME%').createUser({user: '%TENANT_USER%', pwd: '%TENANT_PASS%', roles: [{role: 'readWrite', db: '%SCHEMA_NAME%'}]}); }"
mongosh %MONGO_ARGS% --eval "%JS_CHECK%" --quiet
exit /b 0

:: ## do_sqlite
:: Performs the do_sqlite operation and updates component state.
:do_sqlite
:: schema_name is treated as the file path
for %%I in ("%SCHEMA_NAME%") do set "DB_DIR=%%~dpI"
if not exist "%DB_DIR%" mkdir "%DB_DIR%"
sqlite3 "%SCHEMA_NAME%" "PRAGMA journal_mode=WAL;"
exit /b 0
