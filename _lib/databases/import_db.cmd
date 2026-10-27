@echo off
:: # import_db.cmd
::
:: ## Overview
:: Manifest-driven application state importer for LibScript on Windows.
:: Stops declared services, restores PostgreSQL dumps, DuckDB/SQLite files, and `.env`
:: files from a staging directory, and restarts services.
::
:: ## Usage
:: call _lib\databases\import_db.cmd <libscript.json> <stage_dir>

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

set "JSON_FILE=%~1"
if "!JSON_FILE!"=="" set "JSON_FILE=libscript.json"
set "STAGE_DIR=%~2"
if "!STAGE_DIR!"=="" set "STAGE_DIR=%TEMP%\libscript_import_stage"
if not exist "!JSON_FILE!" exit /b 0

where jq >nul 2>&1
if errorlevel 1 exit /b 0

for %%P in ("!JSON_FILE!") do set "MANIFEST_DIR=%%~dpP"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"

set "APP_NAME="
for /f "delims=" %%n in ('jq -r ".name // empty" "!JSON_FILE!" 2^>nul') do set "APP_NAME=%%n"
if "!APP_NAME!"=="" (
    for %%D in ("!MANIFEST_DIR!") do set "APP_NAME=%%~nxD"
)

set "APP_STAGE=!STAGE_DIR!\!APP_NAME!"
if not exist "!APP_STAGE!" set "APP_STAGE=!STAGE_DIR!"

call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" stop "!JSON_FILE!" >nul 2>&1

if exist "!APP_STAGE!\config\env" copy /y "!APP_STAGE!\config\env" "!MANIFEST_DIR!\.env" >nul
if exist "!APP_STAGE!\config\env.secrets" copy /y "!APP_STAGE!\config\env.secrets" "!MANIFEST_DIR!\.env.secrets" >nul
if exist "!APP_STAGE!\config\env.libscript" copy /y "!APP_STAGE!\config\env.libscript" "!MANIFEST_DIR!\.env.libscript" >nul

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!JSON_FILE!"
)

set "JQ_DB_FILTER=((.databases // .infrastructure.databases) | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == \"array\" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?"
for /f "delims=" %%i in ('jq -c "!JQ_DB_FILTER!" "!JSON_FILE!" 2^>nul') do (
    set "db_entry=%%i"
    call :import_one_db
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" start "!JSON_FILE!"
echo [INFO] Imported state for '!APP_NAME!' from '!APP_STAGE!'.
exit /b 0

:: ## import_one_db
:: Restores a single PostgreSQL, DuckDB, or SQLite database entry from the staging directory.
:import_one_db
set "_eng=postgres"
set "_name=app_db"
set "_user=postgres"
set "_host=127.0.0.1"
set "_port=5432"
set "_pass="
set "_pass_env="
set "_path="

for /f "delims=" %%e in ('echo !db_entry! ^| jq -r "(.engine // .type // \"postgres\") | ascii_downcase" 2^>nul') do set "_eng=%%e"
for /f "delims=" %%n in ('echo !db_entry! ^| jq -r ".name // .db_name // \"app_db\"" 2^>nul') do set "_name=%%n"
for /f "delims=" %%u in ('echo !db_entry! ^| jq -r ".user // .username // \"postgres\"" 2^>nul') do set "_user=%%u"
for /f "delims=" %%h in ('echo !db_entry! ^| jq -r ".host // \"127.0.0.1\"" 2^>nul') do set "_host=%%h"
for /f "delims=" %%P in ('echo !db_entry! ^| jq -r ".port // \"5432\"" 2^>nul') do set "_port=%%P"
for /f "delims=" %%p in ('echo !db_entry! ^| jq -r ".password // empty" 2^>nul') do set "_pass=%%p"
for /f "delims=" %%k in ('echo !db_entry! ^| jq -r ".password_env // empty" 2^>nul') do set "_pass_env=%%k"
for /f "delims=" %%f in ('echo !db_entry! ^| jq -r ".path // .file // .db_path // empty" 2^>nul') do set "_path=%%f"

if "!_pass!"=="" (
    if not "!_pass_env!"=="" (
        for /f "delims=" %%v in ("!_pass_env!") do set "_pass=!%%v!"
    )
)
if "!_pass!"=="" set "_pass=postgres"

if /i "!_eng!"=="postgres" goto :imp_pg
if /i "!_eng!"=="postgresql" goto :imp_pg
if /i "!_eng!"=="duckdb" goto :imp_file
if /i "!_eng!"=="sqlite" goto :imp_file
if /i "!_eng!"=="sqlite3" goto :imp_file
exit /b 0

:: ## imp_pg
:: Restores a PostgreSQL SQL dump into the target database on Windows.
:imp_pg
where psql >nul 2>&1
if errorlevel 1 exit /b 0
set "_sql_src="
if exist "!APP_STAGE!\postgres\!_name!.sql" set "_sql_src=!APP_STAGE!\postgres\!_name!.sql"
if "!_sql_src!"=="" if exist "!STAGE_DIR!\postgres\!_name!.sql" set "_sql_src=!STAGE_DIR!\postgres\!_name!.sql"
if "!_sql_src!"=="" exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine postgres --host "!_host!" --port "!_port!" --admin-user postgres --admin-pass "!_pass!" --schema "!_name!" --user "!_user!" --password "!_pass!" >nul 2>&1
)
set "PGPASSWORD=!_pass!"
echo [INFO] Importing PostgreSQL dump '!_sql_src!' into '!_name!'...
psql -h "!_host!" -p "!_port!" -U "!_user!" -d "!_name!" -f "!_sql_src!" >nul 2>&1
exit /b 0

:: ## imp_file
:: Restores a DuckDB or SQLite database file from the staging directory to its configured path.
:imp_file
if "!_path!"=="" (
    set "_path=!MANIFEST_DIR!\data\!_name!.!_eng!"
) else (
    for /f "delims=" %%x in ('jq -rn --arg s "!_path!" "reduce range(3) as $_ ($s; gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^}]*)\\\\}\"; (env[.k] // \"\") | if . == \"\" then .d else . end) | gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\\\}\"; env[.k] // \"\"))" 2^>nul') do set "_path=%%x"
    set "_path_win=!_path:/=\!"
    if not "!_path_win:~1,1!"==":" set "_path=!MANIFEST_DIR!\!_path_win!"
)
for %%B in ("!_path!") do (
    set "_base_fn=%%~nxB"
    set "_parent_d=%%~dpB"
)
set "_src_f="
if exist "!APP_STAGE!\duckdb\!_base_fn!" set "_src_f=!APP_STAGE!\duckdb\!_base_fn!"
if "!_src_f!"=="" if exist "!STAGE_DIR!\duckdb\!_base_fn!" set "_src_f=!STAGE_DIR!\duckdb\!_base_fn!"
if not "!_src_f!"=="" (
    if not exist "!_parent_d!" mkdir "!_parent_d!"
    if exist "!_path!.wal" del /f /q "!_path!.wal" >nul 2>&1
    echo [INFO] Importing !_eng! file '!_src_f!' -^> '!_path!'...
    copy /y "!_src_f!" "!_path!" >nul
)
exit /b 0
