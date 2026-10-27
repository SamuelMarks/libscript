@echo off
:: # health_db.cmd
::
:: ## Overview
:: Declarative database content and connectivity health verifier for LibScript manifests on Windows.
:: Validates PostgreSQL, DuckDB, SQLite, and Valkey/Redis connectivity, table counts, required tables, row counts, and custom health commands.
::
:: ## Usage
:: Run `health_db.cmd <libscript.json>` to verify declared databases are reachable and populated.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\env_printer.cmd" --hydrate "!JSON_FILE!"
)

if exist "!MANIFEST_DIR!\.env" (
    for /f "usebackq tokens=1* delims==" %%A in ("!MANIFEST_DIR!\.env") do (
        if not "%%A"=="" if not "%%A:~0,1%"=="#" set "%%A=%%B"
    )
)

if exist "!MANIFEST_DIR!\.env.libscript" (
    for /f "usebackq tokens=1* delims==" %%A in ("!MANIFEST_DIR!\.env.libscript") do (
        if not "%%A"=="" if not "%%A:~0,1%"=="#" set "%%A=%%B"
    )
)

set "HEALTH_DB_FAILED=0"
set "JQ_DB_FILTER=((.databases // .infrastructure.databases) | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == \"array\" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?"

for /f "delims=" %%i in ('jq -c "!JQ_DB_FILTER!" "!JSON_FILE!" 2^>nul') do (
    set "db_entry=%%i"
    call :check_db_entry
)

if "!HEALTH_DB_FAILED!"=="1" exit /b 1
exit /b 0

:: ## check_db_entry
:: Validates a single database entry against connectivity, table, row, and command requirements.
:check_db_entry
set "engine=postgres"
set "db_name=app_db"
set "db_user=postgres"
set "db_pass="
set "pass_env="
set "db_host=127.0.0.1"
set "db_port="
set "db_index=0"
set "db_path="
set "min_tables="
set "health_cmd="

for /f "delims=" %%e in ('echo !db_entry! ^| jq -r "(.engine // .type // \"postgres\") | ascii_downcase" 2^>nul') do set "engine=%%e"
for /f "delims=" %%n in ('echo !db_entry! ^| jq -r ".name // .db_name // \"app_db\"" 2^>nul') do set "db_name=%%n"
for /f "delims=" %%u in ('echo !db_entry! ^| jq -r ".user // .username // \"postgres\"" 2^>nul') do set "db_user=%%u"
for /f "delims=" %%p in ('echo !db_entry! ^| jq -r ".password // empty" 2^>nul') do set "db_pass=%%p"
for /f "delims=" %%k in ('echo !db_entry! ^| jq -r ".password_env // empty" 2^>nul') do set "pass_env=%%k"
for /f "delims=" %%h in ('echo !db_entry! ^| jq -r ".host // \"127.0.0.1\"" 2^>nul') do set "db_host=%%h"
for /f "delims=" %%P in ('echo !db_entry! ^| jq -r ".port // empty" 2^>nul') do set "db_port=%%P"
for /f "delims=" %%x in ('echo !db_entry! ^| jq -r ".db_index // .database // 0" 2^>nul') do set "db_index=%%x"
for /f "delims=" %%f in ('echo !db_entry! ^| jq -r ".path // .file // .db_path // empty" 2^>nul') do set "db_path=%%f"
for /f "delims=" %%m in ('echo !db_entry! ^| jq -r "if .min_tables != null then .min_tables elif .require_populated == true then 1 else empty end" 2^>nul') do set "min_tables=%%m"
for /f "delims=" %%c in ('echo !db_entry! ^| jq -r ".health_command // empty" 2^>nul') do set "health_cmd=%%c"

if "!db_pass!"=="" (
    if not "!pass_env!"=="" (
        for /f "delims=" %%v in ("!pass_env!") do set "db_pass=!%%v!"
    )
)
if "!db_pass!"=="" set "db_pass=postgres"
if not "!db_path!"=="" call :expand_vars db_path
if not "!health_cmd!"=="" call :expand_vars health_cmd

if /i "!engine!"=="postgres" call :check_pg
if /i "!engine!"=="postgresql" call :check_pg
if /i "!engine!"=="duckdb" call :check_duckdb
if /i "!engine!"=="sqlite" call :check_sqlite
if /i "!engine!"=="sqlite3" call :check_sqlite
if /i "!engine!"=="valkey" call :check_redis
if /i "!engine!"=="redis" call :check_redis

if not "!health_cmd!"=="" (
    pushd "!MANIFEST_DIR!"
    cmd.exe /c "!health_cmd!"
    if errorlevel 1 (
        echo [ERROR] Database health_command failed for '!db_name!': !health_cmd! >&2
        set "HEALTH_DB_FAILED=1"
    )
    popd
)
exit /b 0

:: ## expand_vars
:: Expands ${VAR:-default} and ${VAR} references in the named variable using jq and env.
:expand_vars
set "_ev_name=%~1"
set "_ev_val=!%_ev_name%!"
for /f "delims=" %%x in ('jq -rn --arg s "!_ev_val!" "reduce range(3) as $_ ($s; gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^}]*)\\\\}\"; (env[.k] // \"\") | if . == \"\" then .d else . end) | gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\\\}\"; env[.k] // \"\"))" 2^>nul') do set "!_ev_name!=%%x"
exit /b 0

:: ## check_pg
:: Validates PostgreSQL database connectivity, minimum tables, and required table row counts.
:check_pg
if "!db_port!"=="" set "db_port=5432"
where psql >nul 2>nul
if errorlevel 1 exit /b 0
set "PGPASSWORD=!db_pass!"
psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -tc "SELECT 1;" >nul 2>&1
if errorlevel 1 (
    echo [ERROR] PostgreSQL health check failed: cannot connect to '!db_name!' on !db_host!:!db_port! >&2
    set "HEALTH_DB_FAILED=1"
    exit /b 0
)
set "pg_tbl_count=0"
for /f "delims= " %%t in ('psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -Atc "SELECT count(*) FROM information_schema.tables WHERE table_schema = 'public' AND table_type = 'BASE TABLE';" 2^>nul') do set "pg_tbl_count=%%t"
if not "!min_tables!"=="" (
    if !pg_tbl_count! lss !min_tables! (
        echo [ERROR] PostgreSQL database '!db_name!' has !pg_tbl_count! tables ^(expected ^>= !min_tables!^) >&2
        set "HEALTH_DB_FAILED=1"
    )
)
for /f "delims=" %%t in ('echo !db_entry! ^| jq -r ".required_tables[]?" 2^>nul') do (
    set "req_tbl=%%t"
    call :check_pg_table
)
echo [INFO] [DB:POSTGRES] [CONFIRM] Database '!db_name!' healthy ^(!pg_tbl_count! table^(s^)^).
exit /b 0

:: ## check_pg_table
:: Checks that a single required PostgreSQL table exists and satisfies minimum row count.
:check_pg_table
set "min_rows_req=1"
for /f "delims=" %%r in ('echo !db_entry! ^| jq -r --arg tbl "!req_tbl!" "if (.min_rows | type) == \"number\" then .min_rows elif (.min_rows | type) == \"object\" then (.min_rows[$tbl] // 1) else 1 end" 2^>nul') do set "min_rows_req=%%r"
set "pg_row_count=-1"
for /f "delims= " %%c in ('psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -Atc "SELECT count(*) FROM \"!req_tbl!\";" 2^>nul') do set "pg_row_count=%%c"
if !pg_row_count! lss !min_rows_req! (
    echo [ERROR] PostgreSQL database '!db_name!' required table '!req_tbl!' has insufficient rows ^(!pg_row_count! ^< !min_rows_req!^) >&2
    set "HEALTH_DB_FAILED=1"
) else (
    echo [INFO] [DB:POSTGRES] [CONFIRM] Table '!db_name!.!req_tbl!' verified ^(!pg_row_count! rows^).
)
exit /b 0

:: ## check_duckdb
:: Validates DuckDB database file existence, non-empty size, minimum tables, and required table row counts.
:check_duckdb
if "!db_path!"=="" (
    set "db_path=!MANIFEST_DIR!\data\!db_name!.duckdb"
) else (
    set "db_path_win=!db_path:/=\!"
    if not "!db_path_win:~1,1!"==":" set "db_path=!MANIFEST_DIR!\!db_path_win!"
)
if not exist "!db_path!" (
    echo [ERROR] DuckDB database file '!db_path!' does not exist. >&2
    set "HEALTH_DB_FAILED=1"
    exit /b 0
)
for %%F in ("!db_path!") do set "duck_size=%%~zF"
if "!duck_size!"=="0" (
    echo [ERROR] DuckDB database file '!db_path!' is empty. >&2
    set "HEALTH_DB_FAILED=1"
    exit /b 0
)
where duckdb >nul 2>nul
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd"
    )
)
set "duck_tbl_count=0"
where duckdb >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%t in ('duckdb "!db_path!" -readonly -csv -noheader -c "SHOW TABLES;" 2^>nul') do set /a duck_tbl_count+=1
)
if not "!min_tables!"=="" (
    if !duck_tbl_count! lss !min_tables! (
        echo [ERROR] DuckDB database '!db_path!' has !duck_tbl_count! tables ^(expected ^>= !min_tables!^) >&2
        set "HEALTH_DB_FAILED=1"
    )
)
for /f "delims=" %%t in ('echo !db_entry! ^| jq -r ".required_tables[]?" 2^>nul') do (
    set "req_tbl=%%t"
    call :check_duckdb_table
)
echo [INFO] [DB:DUCKDB] [CONFIRM] DuckDB '!db_path!' healthy ^(!duck_tbl_count! table^(s^)^).
exit /b 0

:: ## check_duckdb_table
:: Checks that a single required DuckDB table exists and satisfies minimum row count.
:check_duckdb_table
set "min_rows_req=1"
for /f "delims=" %%r in ('echo !db_entry! ^| jq -r --arg tbl "!req_tbl!" "if (.min_rows | type) == \"number\" then .min_rows elif (.min_rows | type) == \"object\" then (.min_rows[$tbl] // 1) else 1 end" 2^>nul') do set "min_rows_req=%%r"
set "duck_row_count=-1"
where duckdb >nul 2>nul
if not errorlevel 1 (
    for /f "delims=" %%c in ('duckdb "!db_path!" -readonly -csv -noheader -c "SELECT COUNT(*) FROM \"!req_tbl!\";" 2^>nul') do set "duck_row_count=%%c"
)
if !duck_row_count! lss !min_rows_req! (
    echo [ERROR] DuckDB database '!db_path!' required table '!req_tbl!' has insufficient rows ^(!duck_row_count! ^< !min_rows_req!^) >&2
    set "HEALTH_DB_FAILED=1"
) else (
    echo [INFO] [DB:DUCKDB] [CONFIRM] Table '!db_name!.!req_tbl!' verified ^(!duck_row_count! rows^).
)
exit /b 0

:: ## check_sqlite
:: Validates SQLite database file existence, minimum tables, and required table row counts.
:check_sqlite
if "!db_path!"=="" (
    set "db_path=!MANIFEST_DIR!\data\!db_name!.sqlite"
) else (
    set "db_path_win=!db_path:/=\!"
    if not "!db_path_win:~1,1!"==":" set "db_path=!MANIFEST_DIR!\!db_path_win!"
)
if not exist "!db_path!" (
    echo [ERROR] SQLite database file '!db_path!' does not exist. >&2
    set "HEALTH_DB_FAILED=1"
    exit /b 0
)
where sqlite3 >nul 2>nul
if errorlevel 1 exit /b 0
set "sqlite_tbl_count=0"
for /f "delims= " %%t in ('sqlite3 "!db_path!" "SELECT count(*) FROM sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%%';" 2^>nul') do set "sqlite_tbl_count=%%t"
if not "!min_tables!"=="" (
    if !sqlite_tbl_count! lss !min_tables! (
        echo [ERROR] SQLite database '!db_path!' has !sqlite_tbl_count! tables ^(expected ^>= !min_tables!^) >&2
        set "HEALTH_DB_FAILED=1"
    )
)
for /f "delims=" %%t in ('echo !db_entry! ^| jq -r ".required_tables[]?" 2^>nul') do (
    set "req_tbl=%%t"
    call :check_sqlite_table
)
echo [INFO] [DB:SQLITE] [CONFIRM] SQLite '!db_path!' healthy ^(!sqlite_tbl_count! table^(s^)^).
exit /b 0

:: ## check_sqlite_table
:: Checks that a single required SQLite table exists and satisfies minimum row count.
:check_sqlite_table
set "min_rows_req=1"
for /f "delims=" %%r in ('echo !db_entry! ^| jq -r --arg tbl "!req_tbl!" "if (.min_rows | type) == \"number\" then .min_rows elif (.min_rows | type) == \"object\" then (.min_rows[$tbl] // 1) else 1 end" 2^>nul') do set "min_rows_req=%%r"
set "sqlite_row_count=-1"
for /f "delims= " %%c in ('sqlite3 "!db_path!" "SELECT count(*) FROM \"!req_tbl!\";" 2^>nul') do set "sqlite_row_count=%%c"
if !sqlite_row_count! lss !min_rows_req! (
    echo [ERROR] SQLite database '!db_path!' required table '!req_tbl!' has insufficient rows ^(!sqlite_row_count! ^< !min_rows_req!^) >&2
    set "HEALTH_DB_FAILED=1"
) else (
    echo [INFO] [DB:SQLITE] [CONFIRM] Table '!db_name!.!req_tbl!' verified ^(!sqlite_row_count! rows^).
)
exit /b 0

:: ## check_redis
:: Validates Valkey/Redis server connectivity on the configured host, port, and database index.
:check_redis
if "!db_port!"=="" set "db_port=6379"
if "!db_index!"=="" set "db_index=0"
if "!db_index!"=="null" set "db_index=0"
set "_vk_has_cli=0"
set "_vk_ok=0"
for %%C in (valkey-cli redis-cli) do (
    where %%C >nul 2>nul
    if not errorlevel 1 (
        set "_vk_has_cli=1"
        for /f "delims=" %%r in ('%%C -h "!db_host!" -p "!db_port!" -n "!db_index!" ping 2^>nul') do (
            if /i "%%r"=="PONG" set "_vk_ok=1"
        )
    )
)
if "!_vk_ok!"=="1" (
    echo [INFO] [DB:VALKEY] [CONFIRM] Valkey/Redis endpoint !db_host!:!db_port! ^(db !db_index!^) healthy.
) else if "!_vk_has_cli!"=="1" (
    echo [ERROR] Valkey/Redis health check failed: no PONG response on !db_host!:!db_port! ^(db !db_index!^). >&2
    set "HEALTH_DB_FAILED=1"
)
exit /b 0
