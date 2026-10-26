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

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!JSON_FILE!"
)

for %%E in ("!MANIFEST_DIR!\.env" "!MANIFEST_DIR!\.env.secrets" "!MANIFEST_DIR!\.env.libscript") do (
    if exist "%%~fE" (
        for /f "usebackq tokens=1* delims==" %%A in ("%%~fE") do (
            if not "%%A"=="" if not "%%A:~0,1%"=="#" set "%%A=%%~B"
        )
    )
)

set "JQ_DB_FILTER=((.databases // .infrastructure.databases) | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == \"array\" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?"

set "PROV_FAILED=0"
for /f "delims=" %%i in ('jq -c "!JQ_DB_FILTER!" "!JSON_FILE!" 2^>nul') do (
    if "!PROV_FAILED!"=="0" (
        set "db_entry=%%i"
        call :process_db_entry
        if errorlevel 1 set "PROV_FAILED=1"
    )
)
if "!PROV_FAILED!"=="1" exit /b 1
exit /b 0

:: ## process_db_entry
:: Provisions a single database definition and writes its connection variables.
:process_db_entry
set "engine=postgres"
set "db_name=app_db"
set "legacy_names="
set "db_user=postgres"
set "db_pass="
set "pass_env="
set "db_host=127.0.0.1"
set "db_port="
set "db_index=0"
set "url_env=DATABASE_URL"
set "sync_url_env="
set "async_url_env="
set "db_env="
set "db_path="
set "seed_file="
set "seed_dir="
set "migration_dir="
set "seed_cmd="

for /f "delims=" %%e in ('echo !db_entry! ^| jq -r "(.engine // .type // \"postgres\") | ascii_downcase" 2^>nul') do set "engine=%%e"
for /f "delims=" %%n in ('echo !db_entry! ^| jq -r ".name // .db_name // \"app_db\"" 2^>nul') do set "db_name=%%n"
for /f "delims=" %%l in ('echo !db_entry! ^| jq -r "(.legacy_names // []) | join(\",\")" 2^>nul') do set "legacy_names=%%l"
for /f "delims=" %%u in ('echo !db_entry! ^| jq -r ".user // .username // \"postgres\"" 2^>nul') do set "db_user=%%u"
for /f "delims=" %%p in ('echo !db_entry! ^| jq -r ".password // empty" 2^>nul') do set "db_pass=%%p"
for /f "delims=" %%k in ('echo !db_entry! ^| jq -r ".password_env // empty" 2^>nul') do set "pass_env=%%k"
for /f "delims=" %%h in ('echo !db_entry! ^| jq -r ".host // \"127.0.0.1\"" 2^>nul') do set "db_host=%%h"
for /f "delims=" %%P in ('echo !db_entry! ^| jq -r ".port // empty" 2^>nul') do set "db_port=%%P"
for /f "delims=" %%x in ('echo !db_entry! ^| jq -r ".db_index // .database // 0" 2^>nul') do set "db_index=%%x"
for /f "delims=" %%v in ('echo !db_entry! ^| jq -r ".url_env // \"DATABASE_URL\"" 2^>nul') do set "url_env=%%v"
for /f "delims=" %%y in ('echo !db_entry! ^| jq -r ".sync_url_env // empty" 2^>nul') do set "sync_url_env=%%y"
for /f "delims=" %%a in ('echo !db_entry! ^| jq -r ".async_url_env // empty" 2^>nul') do set "async_url_env=%%a"
for /f "delims=" %%b in ('echo !db_entry! ^| jq -r ".db_env // empty" 2^>nul') do set "db_env=%%b"
for /f "delims=" %%f in ('echo !db_entry! ^| jq -r ".path // .file // .db_path // empty" 2^>nul') do set "db_path=%%f"
for /f "delims=" %%s in ('echo !db_entry! ^| jq -r ".seed_file // empty" 2^>nul') do set "seed_file=%%s"
for /f "delims=" %%d in ('echo !db_entry! ^| jq -r ".seed_dir // empty" 2^>nul') do set "seed_dir=%%d"
for /f "delims=" %%m in ('echo !db_entry! ^| jq -r ".migration_dir // empty" 2^>nul') do set "migration_dir=%%m"
for /f "delims=" %%c in ('echo !db_entry! ^| jq -r ".seed_command // empty" 2^>nul') do set "seed_cmd=%%c"

if "!db_pass!"=="" (
    if not "!pass_env!"=="" (
        for /f "delims=" %%v in ("!pass_env!") do set "db_pass=!%%v!"
    )
)
if "!db_pass!"=="" set "db_pass=postgres"
if not "!db_path!"=="" call :expand_vars db_path
if not "!seed_cmd!"=="" call :expand_vars seed_cmd

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

:: ## expand_vars
:: Expands ${VAR:-default} and ${VAR} references in the named variable using jq and env.
:expand_vars
set "_ev_name=%~1"
set "_ev_val=!%_ev_name%!"
for /f "delims=" %%x in ('jq -rn --arg s "!_ev_val!" "reduce range(3) as $_ ($s; gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^}]*)\\\\}\"; (env[.k] // \"\") | if . == \"\" then .d else . end) | gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\\\}\"; env[.k] // \"\"))" 2^>nul') do set "!_ev_name!=%%x"
exit /b 0

:: ## prov_pg
:: Provisions a PostgreSQL database with reuse-else-create semantics and writes connection URLs.
:prov_pg
if "!db_port!"=="" set "db_port=5432"
echo [INFO] Provisioning PostgreSQL database '!db_name!' (user: !db_user!, host: !db_host!:!db_port!)...
set "_pg_ready=0"
where pg_isready >nul 2>nul
if not errorlevel 1 (
    pg_isready -h "!db_host!" -p "!db_port!" -q >nul 2>&1
    if not errorlevel 1 set "_pg_ready=1"
)
if "!_pg_ready!"=="1" (
    echo [REUSE] PostgreSQL server is already active on !db_host!:!db_port!.
) else if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\cli.cmd" start >nul 2>&1
)
call :set_env_var "!url_env!" "postgresql://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
if not "!sync_url_env!"=="" call :set_env_var "!sync_url_env!" "postgresql://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
if not "!async_url_env!"=="" call :set_env_var "!async_url_env!" "postgresql+asyncpg://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
if not "!db_env!"=="" call :set_env_var "!db_env!" "!db_name!"
where psql >nul 2>nul
if not errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine postgres --host "!db_host!" --port "!db_port!" --admin-user postgres --admin-pass "!db_pass!" --schema "!db_name!" --legacy-names "!legacy_names!" --user "!db_user!" --password "!db_pass!" >nul 2>&1
    )
    if not "!seed_file!"=="" (
        set "sf_win=!seed_file:/=\!"
        if not "!sf_win:~1,1!"==":" set "sf_win=!MANIFEST_DIR!\!sf_win!"
        set "PGPASSWORD=!db_pass!"
        if exist "!sf_win!" psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -f "!sf_win!" >nul 2>&1
    )
)
if not "!seed_cmd!"=="" (
    call :check_pg_populated
    if not errorlevel 1 (
        echo [REUSE] PostgreSQL database '!db_name!' already has required tables and minimum rows; skipping full re-seed.
    ) else (
        pushd "!MANIFEST_DIR!"
        cmd.exe /c "!seed_cmd!"
        set "rc=!errorlevel!"
        popd
        if not "!rc!"=="0" exit /b !rc!
    )
)
exit /b 0

:: ## check_pg_populated
:: Checks whether all min_tables, required_tables, and min_rows in a PostgreSQL database are satisfied on Windows.
:check_pg_populated
if "!LIBSCRIPT_FORCE_SEED!"=="1" exit /b 1
where psql >nul 2>nul
if errorlevel 1 exit /b 1
set "_cpp_has_req=0"
set "_cpp_min_tbl="
set "PGPASSWORD=!db_pass!"
for /f "delims=" %%m in ('echo !db_entry! ^| jq -r ".min_tables // empty" 2^>nul') do set "_cpp_min_tbl=%%m"
if not "!_cpp_min_tbl!"=="" (
    set "_cpp_has_req=1"
    set "_cpp_cnt=0"
    for /f "delims= " %%c in ('psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2^>nul') do set "_cpp_cnt=%%c"
    if !_cpp_cnt! lss !_cpp_min_tbl! exit /b 1
)
for /f "delims=" %%t in ('echo !db_entry! ^| jq -r ".required_tables[]?" 2^>nul') do (
    set "_cpp_has_req=1"
    set "_cpp_tbl=%%t"
    set "_cpp_min_r=1"
    for /f "delims=" %%r in ('echo !db_entry! ^| jq -r --arg tbl "%%t" "if (.min_rows | type) == \"number\" then .min_rows elif (.min_rows | type) == \"object\" then (.min_rows[$tbl] // 1) else 1 end" 2^>nul') do set "_cpp_min_r=%%r"
    set "_cpp_rc=-1"
    for /f "delims= " %%c in ('psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -Atc "SELECT count(*) FROM \"%%t\";" 2^>nul') do set "_cpp_rc=%%c"
    if !_cpp_rc! lss !_cpp_min_r! exit /b 1
)
if "!_cpp_has_req!"=="0" exit /b 1
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
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine mysql --host "!db_host!" --port "!db_port!" --admin-user root --schema "!db_name!" --user "!db_user!" --password "!db_pass!" >nul 2>&1
    )
)
call :set_env_var "!url_env!" "mysql://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
if not "!seed_cmd!"=="" (
    pushd "!MANIFEST_DIR!"
    cmd.exe /c "!seed_cmd!"
    set "rc=!errorlevel!"
    popd
    if not "!rc!"=="0" exit /b !rc!
)
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
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
    where sqlite3 >nul 2>nul
    if not errorlevel 1 (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine sqlite --schema "!db_path!" --user "!db_user!" --password "!db_pass!" >nul 2>&1
    )
)
call :set_env_var "!url_env!" "sqlite:///!db_path:\=/!"
call :set_env_var "SQLITE_PATH" "!db_path!"
if not "!seed_cmd!"=="" (
    pushd "!MANIFEST_DIR!"
    cmd.exe /c "!seed_cmd!"
    set "rc=!errorlevel!"
    popd
    if not "!rc!"=="0" exit /b !rc!
)
exit /b 0

:: ## prov_duckdb
:: Ensures parent directory and valid DuckDB database file exist, runs seeds, and writes DUCKDB_PATH.
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
set "path_env=DUCKDB_PATH"
for /f "delims=" %%k in ('echo !db_entry! ^| jq -r ".path_env // .env_var // \"DUCKDB_PATH\"" 2^>nul') do set "path_env=%%k"
call :set_env_var "!path_env!" "!db_path!"
if not "!path_env!"=="DUCKDB_PATH" (
    call :set_env_var "DUCKDB_PATH" "!db_path!"
)
if not "!url_env!"=="DATABASE_URL" (
    call :set_env_var "!url_env!" "duckdb:///!db_path:\=/!"
)
where duckdb >nul 2>nul
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd"
    )
)
if not exist "!db_path!" (
    where duckdb >nul 2>nul
    if not errorlevel 1 (
        duckdb "!db_path!" -c "SELECT 1;" >nul 2>&1
    )
)
if not "!seed_file!"=="" (
    set "sf_win=!seed_file:/=\!"
    if not "!sf_win:~1,1!"==":" set "sf_win=!MANIFEST_DIR!\!sf_win!"
    if exist "!sf_win!" call :exec_duckdb_sql "!db_path!" "!sf_win!"
)
if not "!seed_dir!"=="" (
    set "sd_win=!seed_dir:/=\!"
    if not "!sd_win:~1,1!"==":" set "sd_win=!MANIFEST_DIR!\!sd_win!"
    if exist "!sd_win!" (
        for %%S in ("!sd_win!\*.sql") do call :exec_duckdb_sql "!db_path!" "%%~fS"
        for %%C in ("!sd_win!\*.csv") do call :import_duckdb_file "!db_path!" "%%~fC" "%%~nC"
        for %%Q in ("!sd_win!\*.parquet") do call :import_duckdb_file "!db_path!" "%%~fQ" "%%~nQ"
    )
)
if not "!seed_cmd!"=="" (
    call :check_duckdb_populated
    if not errorlevel 1 (
        echo [REUSE] DuckDB database '!db_path!' already has required tables and minimum rows; skipping full re-seed.
    ) else (
        pushd "!MANIFEST_DIR!"
        cmd.exe /c "!seed_cmd!"
        set "rc=!errorlevel!"
        popd
        if not "!rc!"=="0" exit /b !rc!
    )
)
exit /b 0

:: ## check_duckdb_populated
:: Checks whether all min_tables, required_tables, and min_rows in a DuckDB database file are satisfied on Windows.
:check_duckdb_populated
if "!LIBSCRIPT_FORCE_SEED!"=="1" exit /b 1
if not exist "!db_path!" exit /b 1
where duckdb >nul 2>nul
if errorlevel 1 exit /b 1
set "_cdp_has_req=0"
set "_cdp_min_tbl="
for /f "delims=" %%m in ('echo !db_entry! ^| jq -r ".min_tables // empty" 2^>nul') do set "_cdp_min_tbl=%%m"
if not "!_cdp_min_tbl!"=="" (
    set "_cdp_has_req=1"
    set "_cdp_cnt=0"
    for /f "delims=" %%c in ('duckdb "!db_path!" -readonly -csv -noheader -c "SHOW TABLES;" 2^>nul') do set /a _cdp_cnt+=1
    if !_cdp_cnt! lss !_cdp_min_tbl! exit /b 1
)
for /f "delims=" %%t in ('echo !db_entry! ^| jq -r ".required_tables[]?" 2^>nul') do (
    set "_cdp_has_req=1"
    set "_cdp_min_r=1"
    for /f "delims=" %%r in ('echo !db_entry! ^| jq -r --arg tbl "%%t" "if (.min_rows | type) == \"number\" then .min_rows elif (.min_rows | type) == \"object\" then (.min_rows[$tbl] // 1) else 1 end" 2^>nul') do set "_cdp_min_r=%%r"
    set "_cdp_rc=-1"
    for /f "delims=" %%c in ('duckdb "!db_path!" -readonly -csv -noheader -c "SELECT COUNT(*) FROM \"%%t\";" 2^>nul') do set "_cdp_rc=%%c"
    if !_cdp_rc! lss !_cdp_min_r! exit /b 1
)
if "!_cdp_has_req!"=="0" exit /b 1
exit /b 0

:: ## exec_duckdb_sql
:: Executes a SQL script file against the target DuckDB database.
:exec_duckdb_sql
where duckdb >nul 2>nul
if not errorlevel 1 (
    duckdb "%~1" < "%~2" >nul 2>&1
)
exit /b 0

:: ## import_duckdb_file
:: Imports a CSV or Parquet file into DuckDB as a table named after the file stem.
:import_duckdb_file
set "_idf_file=%~2"
set "_idf_fwd=!_idf_file:\=/!"
where duckdb >nul 2>nul
if not errorlevel 1 (
    duckdb "%~1" -c "CREATE TABLE IF NOT EXISTS \"%~3\" AS SELECT * FROM '!_idf_fwd!';" >nul 2>&1
)
exit /b 0

:: ## prov_redis
:: Starts Valkey/Redis service if available and writes REDIS_URL / VALKEY_URL with reuse-else-create semantics.
:prov_redis
if "!db_port!"=="" set "db_port=6379"
if "!db_index!"=="" set "db_index=0"
if "!db_index!"=="null" set "db_index=0"
echo [INFO] Provisioning Valkey/Redis cache endpoint (!db_host!:!db_port!/!db_index!)...
set "_valkey_ready=0"
for %%C in (valkey-cli redis-cli) do (
    where %%C >nul 2>nul
    if not errorlevel 1 (
        for /f "delims=" %%r in ('%%C -h "!db_host!" -p "!db_port!" -n "!db_index!" ping 2^>nul') do (
            if /i "%%r"=="PONG" set "_valkey_ready=1"
        )
    )
)
if "!_valkey_ready!"=="1" (
    echo [REUSE] Valkey/Redis server already active on !db_host!:!db_port! ^(db !db_index!^).
) else (
    echo [CREATE] Starting Valkey/Redis server on !db_host!:!db_port!...
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\caches\valkey\cli.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\caches\valkey\cli.cmd" start >nul 2>&1
    )
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\caches\redis\cli.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\caches\redis\cli.cmd" start >nul 2>&1
    )
)
call :set_env_var "REDIS_URL" "redis://!db_host!:!db_port!/!db_index!"
call :set_env_var "VALKEY_URL" "redis://!db_host!:!db_port!/!db_index!"
if not "!url_env!"=="" if not "!url_env!"=="DATABASE_URL" (
    call :set_env_var "!url_env!" "redis://!db_host!:!db_port!/!db_index!"
)
exit /b 0

:: ## set_env_var
:: Idempotently updates or appends a key-value pair in .env.libscript.
:set_env_var
if "%~1"=="" exit /b 0
if exist "!ENV_OUT!" (
    findstr /v /b /c:"%~1=" "!ENV_OUT!" > "!ENV_OUT!.tmp" 2>nul
    move /y "!ENV_OUT!.tmp" "!ENV_OUT!" >nul 2>&1
)
echo %~1=%~2>> "!ENV_OUT!"
exit /b 0
