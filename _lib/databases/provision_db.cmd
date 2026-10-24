@echo off
:: # provision_db.cmd
::
:: ## Overview
:: Declarative database and cache provisioning engine for LibScript manifests on Windows.
:: Initializes Postgres, MySQL/MariaDB, SQLite, DuckDB, and Valkey/Redis users/databases and exports connection URLs.
::
:: ## Usage
:: Run `provision_db.cmd <libscript.json>` to provision declared databases and emit `.env.libscript`.

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

set "JSON_FILE=%~1"
if "!JSON_FILE!"=="" set "JSON_FILE=libscript.json"
if not exist "!JSON_FILE!" exit /b 0

where jq >nul 2>nul
if errorlevel 1 exit /b 0

for %%P in ("!JSON_FILE!") do set "MANIFEST_DIR=%%~dpP"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"
set "ENV_OUT=!MANIFEST_DIR!\.env.libscript"

set "JQ_DB_FILTER=(.databases | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == \"array\" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?"

for /f "delims=" %%i in ('jq -c "!JQ_DB_FILTER!" "!JSON_FILE!" 2^>nul') do (
    set "db_entry=%%i"
    call :process_db_entry
)
exit /b 0

:: ## process_db_entry
:: Provisions a single database definition and writes its connection variables.
:process_db_entry
set "engine=postgres"
set "db_name=app_db"
set "db_user=postgres"
set "db_pass=postgres"
set "db_host=127.0.0.1"
set "db_port="
set "url_env=DATABASE_URL"
set "db_path="

for /f "delims=" %%e in ('echo !db_entry! ^| jq -r "(.engine // .type // \"postgres\") | ascii_downcase" 2^>nul') do set "engine=%%e"
for /f "delims=" %%n in ('echo !db_entry! ^| jq -r ".name // .db_name // \"app_db\"" 2^>nul') do set "db_name=%%n"
for /f "delims=" %%u in ('echo !db_entry! ^| jq -r ".user // .username // \"postgres\"" 2^>nul') do set "db_user=%%u"
for /f "delims=" %%p in ('echo !db_entry! ^| jq -r ".password // \"postgres\"" 2^>nul') do set "db_pass=%%p"
for /f "delims=" %%h in ('echo !db_entry! ^| jq -r ".host // \"127.0.0.1\"" 2^>nul') do set "db_host=%%h"
for /f "delims=" %%P in ('echo !db_entry! ^| jq -r ".port // empty" 2^>nul') do set "db_port=%%P"
for /f "delims=" %%v in ('echo !db_entry! ^| jq -r ".url_env // \"DATABASE_URL\"" 2^>nul') do set "url_env=%%v"
for /f "delims=" %%f in ('echo !db_entry! ^| jq -r ".path // .file // empty" 2^>nul') do set "db_path=%%f"

if /i "!engine!"=="postgres" goto :prov_pg
if /i "!engine!"=="postgresql" goto :prov_pg
if /i "!engine!"=="mysql" goto :prov_mysql
if /i "!engine!"=="mariadb" goto :prov_mysql
if /i "!engine!"=="sqlite" goto :prov_sqlite
if /i "!engine!"=="sqlite3" goto :prov_sqlite
if /i "!engine!"=="duckdb" goto :prov_duckdb
if /i "!engine!"=="valkey" goto :prov_redis
if /i "!engine!"=="redis" goto :prov_redis
exit /b 0

:: ## prov_pg
:: Provisions a PostgreSQL database and writes DATABASE_URL.
:prov_pg
if "!db_port!"=="" set "db_port=5432"
echo [INFO] Provisioning PostgreSQL database '!db_name!' (user: !db_user!, host: !db_host!:!db_port!)...
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\cli.cmd" start >nul 2>&1
)
where psql >nul 2>nul
if not errorlevel 1 (
    psql -h "!db_host!" -p "!db_port!" -U postgres -c "CREATE USER "!db_user!" WITH PASSWORD '!db_pass!';" >nul 2>&1
    psql -h "!db_host!" -p "!db_port!" -U postgres -c "CREATE DATABASE "!db_name!" OWNER "!db_user!";" >nul 2>&1
    psql -h "!db_host!" -p "!db_port!" -U postgres -c "GRANT ALL PRIVILEGES ON DATABASE "!db_name!" TO "!db_user!";" >nul 2>&1
)
call :set_env_var "!url_env!" "postgresql://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
exit /b 0

:: ## prov_mysql
:: Provisions a MySQL or MariaDB database and writes DATABASE_URL.
:prov_mysql
if "!db_port!"=="" set "db_port=3306"
echo [INFO] Provisioning MySQL/MariaDB database '!db_name!' (user: !db_user!, host: !db_host!:!db_port!)...
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\mariadb\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\mariadb\cli.cmd" start >nul 2>&1
)
where mysql >nul 2>nul
if not errorlevel 1 (
    mysql -h "!db_host!" -P "!db_port!" -u root -e "CREATE DATABASE IF NOT EXISTS `!db_name!`; CREATE USER IF NOT EXISTS '!db_user!'@'%%' IDENTIFIED BY '!db_pass!'; GRANT ALL PRIVILEGES ON `!db_name!`.* TO '!db_user!'@'%%'; FLUSH PRIVILEGES;" >nul 2>&1
)
call :set_env_var "!url_env!" "mysql://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
exit /b 0

:: ## prov_sqlite
:: Ensures parent directory for SQLite database exists and writes SQLITE_PATH / DATABASE_URL.
:prov_sqlite
if "!db_path!"=="" (
    set "db_path=!MANIFEST_DIR!\data\!db_name!.sqlite"
) else (
    set "db_path_win=!db_path:/=\!"
    if not "!db_path_win:~1,1!"==":" set "db_path=!MANIFEST_DIR!\!db_path_win!"
)
for %%D in ("!db_path!") do set "db_dir=%%~dpD"
if not exist "!db_dir!" mkdir "!db_dir!"
echo [INFO] Provisioning SQLite database at '!db_path!'...
call :set_env_var "!url_env!" "sqlite:///!db_path:\=/!"
call :set_env_var "SQLITE_PATH" "!db_path!"
exit /b 0

:: ## prov_duckdb
:: Ensures parent directory for DuckDB database exists and writes DUCKDB_PATH.
:prov_duckdb
if "!db_path!"=="" (
    set "db_path=!MANIFEST_DIR!\data\!db_name!.duckdb"
) else (
    set "db_path_win=!db_path:/=\!"
    if not "!db_path_win:~1,1!"==":" set "db_path=!MANIFEST_DIR!\!db_path_win!"
)
for %%D in ("!db_path!") do set "db_dir=%%~dpD"
if not exist "!db_dir!" mkdir "!db_dir!"
echo [INFO] Provisioning DuckDB database at '!db_path!'...
call :set_env_var "DUCKDB_PATH" "!db_path!"
exit /b 0

:: ## prov_redis
:: Starts Valkey/Redis service if available and writes REDIS_URL / VALKEY_URL.
:prov_redis
if "!db_port!"=="" set "db_port=6379"
echo [INFO] Provisioning Valkey/Redis cache endpoint (!db_host!:!db_port!)...
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\caches\valkey\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\caches\valkey\cli.cmd" start >nul 2>&1
)
call :set_env_var "REDIS_URL" "redis://!db_host!:!db_port!/0"
call :set_env_var "VALKEY_URL" "redis://!db_host!:!db_port!/0"
exit /b 0

:: ## set_env_var
:: Idempotently updates or appends a key-value pair in .env.libscript.
:set_env_var
if exist "!ENV_OUT!" (
    findstr /v /b /c:"%~1=" "!ENV_OUT!" > "!ENV_OUT!.tmp" 2>nul
    move /y "!ENV_OUT!.tmp" "!ENV_OUT!" >nul 2>&1
)
echo %~1=%~2>> "!ENV_OUT!"
exit /b 0
