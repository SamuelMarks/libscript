@echo off
:: # provision_db.cmd
:: ## Overview
:: Declarative database and cache provisioning engine for LibScript manifests on Windows. Initializes Postgres, MySQL/MariaDB, SQLite, DuckDB, and Valkey/Redis users/databases and exports connection URLs.
:: ## Usage
:: Run `provision_db.cmd <libscript.json>` to provision declared databases and emit `.env.libscript`.

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
if defined SERVICE_PATH set "PATH=!SERVICE_PATH!;!PATH!"
if defined SERVICE_EXTRA_PATH set "PATH=!SERVICE_EXTRA_PATH!;!PATH!"
call :dedup_prov_path

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

:: ## dedup_prov_path
:: Deduplicates semicolon-separated entries in PATH and updates SERVICE_PATH.
:dedup_prov_path
set "_DPP_OUT="
for %%P in ("!PATH:;=" "!") do (
    set "_DPP_SEG=%%~P"
    if not "!_DPP_SEG!"=="" (
        echo ";!_DPP_OUT!;" | findstr /I /C:";!_DPP_SEG!;" >nul 2>&1
        if errorlevel 1 (
            if defined _DPP_OUT (
                set "_DPP_OUT=!_DPP_OUT!;!_DPP_SEG!"
            ) else (
                set "_DPP_OUT=!_DPP_SEG!"
            )
        )
    )
)
if defined _DPP_OUT (
    set "PATH=!_DPP_OUT!"
    set "SERVICE_PATH=!_DPP_OUT!"
)
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
:: Expands ${VAR:-default} and ${VAR} references in the named variable using jq and env while preserving quotes and local $_vars.
:expand_vars
set "_ev_name=%~1"
set "_ev_val=!%_ev_name%!"
if "!_ev_val!"=="" exit /b 0
for /f "delims=" %%x in ('jq -rn "reduce range(6) as $_ ($ENV._ev_val; gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*):-(?<d>[^{}]*)\\\\}\"; if (.k | startswith(\"_\")) and ((env[.k] // \"\") == \"\") then \"${\" + .k + \":-\" + .d + \"}\" else (env[.k] // \"\") | if . == \"\" then .d else . end end) | gsub(\"\\\\$\\\\{(?<k>[A-Za-z_][A-Za-z0-9_]*)\\\\}\"; if (.k | startswith(\"_\")) and ((env[.k] // \"\") == \"\") then \"${\" + .k + \"}\" else (env[.k] // \"\") end))" 2^>nul') do set "!_ev_name!=%%x"
exit /b 0

:: ## prov_pg
:: Provisions a PostgreSQL database with reuse-else-create semantics and writes connection URLs.
:prov_pg
if "!db_port!"=="" set "db_port=5432"
echo [INFO] [DB:POSTGRES] Provisioning PostgreSQL database '!db_name!' ^(user: !db_user!, host: !db_host!:!db_port!^)...
set "_pg_ready=0"
where pg_isready >nul 2>nul
if not errorlevel 1 (
    pg_isready -h "!db_host!" -p "!db_port!" -q >nul 2>&1
    if not errorlevel 1 set "_pg_ready=1"
)
if "!_pg_ready!"=="1" (
    echo [INFO] [DB:POSTGRES] [CONFIRM] PostgreSQL server is active on !db_host!:!db_port!.
) else if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\cli.cmd" (
    echo [INFO] [DB:POSTGRES] [CREATE] Starting PostgreSQL server on !db_host!:!db_port!...
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
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine postgres --host "!db_host!" --port "!db_port!" --admin-user postgres --admin-pass "!db_pass!" --schema "!db_name!" --legacy-names "!legacy_names!" --user "!db_user!" --password "!db_pass!"
    )
    if not "!seed_file!"=="" (
        set "sf_win=!seed_file:/=\!"
        if not "!sf_win:~1,1!"==":" set "sf_win=!MANIFEST_DIR!\!sf_win!"
        set "PGPASSWORD=!db_pass!"
        if exist "!sf_win!" (
            set "_DB_STATE_DIR=%USERPROFILE%\.libscript_db_state"
            if not exist "!_DB_STATE_DIR!" mkdir "!_DB_STATE_DIR!" >nul 2>&1
            set "_SF_SIG="
            for %%Z in ("!sf_win!") do set "_SF_SIG=%%~nxZ_%%~zZ_%%~tZ"
            set "_SF_SIG=!_SF_SIG: =_!"
            set "_SF_CACHED="
            if exist "!_DB_STATE_DIR!\pg_!db_name!_seed.sha256" set /p _SF_CACHED=<"!_DB_STATE_DIR!\pg_!db_name!_seed.sha256"
            set "_SKIP_PG_SEED_FILE=0"
            if not "!LIBSCRIPT_FORCE_SEED!"=="1" if not "!_SF_CACHED!"=="" if "!_SF_CACHED!"=="!_SF_SIG!" set "_SKIP_PG_SEED_FILE=1"
            if "!_SKIP_PG_SEED_FILE!"=="1" (
                echo [INFO] [REUSE] PostgreSQL seed_file '!sf_win!' unchanged for '!db_name!'; skipping.
            ) else (
                psql -h "!db_host!" -p "!db_port!" -U "!db_user!" -d "!db_name!" -f "!sf_win!" >nul 2>&1
                > "!_DB_STATE_DIR!\pg_!db_name!_seed.sha256" echo !_SF_SIG!
            )
        )
    )
)
if not "!seed_cmd!"=="" (
    call :check_pg_populated
    if not errorlevel 1 (
        echo [INFO] [REUSE] PostgreSQL database '!db_name!' already has required tables and minimum rows; skipping full re-seed.
        call :set_env_var "LIBSCRIPT_DB_POSTGRES_POPULATED" "1"
    ) else (
        echo [INFO] [UPSERT:POSTGRES] Running PostgreSQL seed_command for '!db_name!': !seed_cmd!
        pushd "!MANIFEST_DIR!"
        cmd.exe /c "!seed_cmd!"
        set "rc=!errorlevel!"
        popd
        if not "!rc!"=="0" exit /b !rc!
        call :set_env_var "LIBSCRIPT_DB_POSTGRES_POPULATED" "1"
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
    echo [INFO] [DB:POSTGRES] [CONFIRM] Table '!db_name!.%%t' verified ^(!_cpp_rc! rows^).
)
if "!_cpp_has_req!"=="0" exit /b 1
exit /b 0

:: ## prov_mysql
:: Provisions a MySQL or MariaDB database and writes DATABASE_URL.
:prov_mysql
if "!db_port!"=="" set "db_port=3306"
echo [INFO] [DB:MYSQL] Provisioning MySQL/MariaDB database '!db_name!' ^(user: !db_user!, host: !db_host!:!db_port!^)...
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\mariadb\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\mariadb\cli.cmd" start >nul 2>&1
)
where mysql >nul 2>nul
if not errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine mysql --host "!db_host!" --port "!db_port!" --admin-user root --schema "!db_name!" --user "!db_user!" --password "!db_pass!"
    )
)
call :set_env_var "!url_env!" "mysql://!db_user!:!db_pass!@!db_host!:!db_port!/!db_name!"
if not "!seed_cmd!"=="" (
    echo [INFO] [UPSERT:MYSQL] Running MySQL/MariaDB seed_command for '!db_name!': !seed_cmd!
    pushd "!MANIFEST_DIR!"
    cmd.exe /c "!seed_cmd!"
    set "rc=!errorlevel!"
    popd
    if not "!rc!"=="0" exit /b !rc!
)
exit /b 0

:: ## prov_sqlite
:: Provisions a SQLite database file and writes SQLITE_PATH.
:prov_sqlite
if "!db_path!"=="" (
    set "db_path=!MANIFEST_DIR!\data\!db_name!.sqlite"
) else (
    set "db_path_win=!db_path:/=\!"
    if not "!db_path_win:~1,1!"==":" set "db_path=!MANIFEST_DIR!\!db_path_win!"
)
for %%D in ("!db_path!") do set "db_dir=%%~dpD"
if not exist "!db_dir!" mkdir "!db_dir!"
echo [INFO] [DB:SQLITE] Provisioning SQLite database at '!db_path!'...
where sqlite3 >nul 2>nul
if not errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\provision_schema.cmd" --engine sqlite --schema "!db_path!" --user "!db_user!" --password "!db_pass!"
    )
)
call :set_env_var "!url_env!" "sqlite:///!db_path:\=/!"
call :set_env_var "SQLITE_PATH" "!db_path!"
if not "!seed_cmd!"=="" (
    echo [INFO] [UPSERT:SQLITE] Running SQLite seed_command for '!db_name!': !seed_cmd!
    pushd "!MANIFEST_DIR!"
    cmd.exe /c "!seed_cmd!"
    set "rc=!errorlevel!"
    popd
    if not "!rc!"=="0" exit /b !rc!
)
exit /b 0

:: ## find_manifest_duckdb_python
:: Searches manifest virtualenvs, LIBSCRIPT_HOME, and PATH for a Python interpreter with duckdb installed.
:find_manifest_duckdb_python
set "DUCKDB_PY_BIN="
for %%P in ("!MANIFEST_DIR!\.venv\Scripts\python.exe" "!MANIFEST_DIR!\.venv\bin\python") do (
    if exist "%%~fP" (
        "%%~fP" -c "import duckdb" >nul 2>&1
        if not errorlevel 1 (
            set "DUCKDB_PY_BIN=%%~fP"
            exit /b 0
        )
    )
)
for /d %%D in ("!MANIFEST_DIR!\*") do (
    if exist "%%~fD\.venv\Scripts\python.exe" (
        "%%~fD\.venv\Scripts\python.exe" -c "import duckdb" >nul 2>&1
        if not errorlevel 1 (
            set "DUCKDB_PY_BIN=%%~fD\.venv\Scripts\python.exe"
            exit /b 0
        )
    )
)
for %%P in (python python3) do (
    where %%P >nul 2>&1
    if not errorlevel 1 (
        %%P -c "import duckdb" >nul 2>&1
        if not errorlevel 1 (
            set "DUCKDB_PY_BIN=%%P"
            exit /b 0
        )
    )
)
exit /b 1

:: ## query_duckdb_scalar
:: Executes a scalar SQL query against a DuckDB database file using the duckdb CLI with Python duckdb fallback.
:query_duckdb_scalar
set "_qds_path=%~1"
set "_qds_sql=%~2"
set "_qds_mode=%~3"
if "!_qds_mode!"=="" set "_qds_mode=scalar"
set "QDS_OUT="
where duckdb >nul 2>nul
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd"
    )
)
where duckdb >nul 2>nul
if not errorlevel 1 (
    if /i "!_qds_mode!"=="len" (
        set /a _qds_len=0
        for /f "delims=" %%L in ('duckdb "!_qds_path!" -readonly -csv -noheader -c "!_qds_sql!" 2^>nul') do set /a _qds_len+=1
        set "QDS_OUT=!_qds_len!"
    ) else (
        for /f "delims=" %%L in ('duckdb "!_qds_path!" -readonly -csv -noheader -c "!_qds_sql!" 2^>nul') do if "!QDS_OUT!"=="" set "QDS_OUT=%%L"
    )
)
if "!QDS_OUT!"=="" set "QDS_OUT=0"
if "!QDS_OUT!"=="0" if exist "!_qds_path!" (
    call :find_manifest_duckdb_python
    if not errorlevel 1 if not "!DUCKDB_PY_BIN!"=="" (
        for /f "delims=" %%R in ('"!DUCKDB_PY_BIN!" -c "import sys,duckdb; con=duckdb.connect(sys.argv[1],read_only=True); rows=con.execute(sys.argv[2]).fetchall(); con.close(); print(len(rows) if sys.argv[3]=='len' else (rows[0][0] if rows and rows[0] else 0))" "!_qds_path!" "!_qds_sql!" "!_qds_mode!" 2^>nul') do set "QDS_OUT=%%R"
    )
)
if "!QDS_OUT!"=="" set "QDS_OUT=0"
exit /b 0

:: ## prov_duckdb
:: Provisions a DuckDB database file, imports seed SQL/CSV/Parquet, and writes DUCKDB_PATH.
:prov_duckdb
set "db_read_only=0"
for /f "delims=" %%o in ('echo !db_entry! ^| jq -r "if .read_only == true or .readonly == true then \"1\" else \"0\" end" 2^>nul') do set "db_read_only=%%o"
if "!db_path!"=="" (
    set "_pdb_def_mount=%DATA_DISK_MOUNT%"
    if "!_pdb_def_mount!"=="" set "_pdb_def_mount=%DATA_MOUNT_DIR%"
    if "!_pdb_def_mount!"=="" set "_pdb_def_mount=/mnt/data"
    if exist "!_pdb_def_mount!" (
        set "db_path=!_pdb_def_mount!\!db_name!.duckdb"
    ) else (
        set "db_path=!MANIFEST_DIR!\data\!db_name!.duckdb"
    )
) else (
    set "db_path_win=!db_path:/=\!"
    if not "!db_path_win:~1,1!"==":" set "db_path=!MANIFEST_DIR!\!db_path_win!"
)
for %%D in ("!db_path!") do set "db_dir=%%~dpD"
if not "!db_read_only!"=="1" (
    if not exist "!db_dir!" mkdir "!db_dir!"
)
set "path_env=DUCKDB_PATH"
for /f "delims=" %%k in ('echo !db_entry! ^| jq -r ".path_env // .env_var // \"DUCKDB_PATH\"" 2^>nul') do set "path_env=%%k"
call :set_env_var "!path_env!" "!db_path!"
if not "!path_env!"=="DUCKDB_PATH" if not "!db_read_only!"=="1" (
    call :set_env_var "DUCKDB_PATH" "!db_path!"
)
if not "!url_env!"=="DATABASE_URL" (
    call :set_env_var "!url_env!" "duckdb:///!db_path:\=/!"
)
if "!db_read_only!"=="1" (
    if exist "!db_path!" (
        call :query_duckdb_scalar "!db_path!" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');" "scalar"
        set "_duck_tcnt=!QDS_OUT!"
        for %%Z in ("!db_path!") do set "_duck_sz=%%~zZ"
        echo [INFO] [DB:DUCKDB] [CONFIRM] Read-only DuckDB database exists at '!db_path!' ^(!_duck_sz! bytes, !_duck_tcnt! table^(s^)^).
        call :check_duckdb_populated
    ) else (
        echo [WARN] [DB:DUCKDB] Read-only DuckDB database '!db_path!' is not present yet; skipping write provisioning.
    )
    exit /b 0
)
where duckdb >nul 2>nul
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\duckdb\env.cmd"
    )
)
if not exist "!db_path!" (
    echo [INFO] [DB:DUCKDB] [CREATE] Initializing new DuckDB database at '!db_path!'...
    where duckdb >nul 2>nul
    if not errorlevel 1 (
        duckdb "!db_path!" -c "SELECT 1;" >nul 2>&1
    )
) else (
    call :query_duckdb_scalar "!db_path!" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');" "scalar"
    set "_duck_tcnt=!QDS_OUT!"
    for %%Z in ("!db_path!") do set "_duck_sz=%%~zZ"
    echo [INFO] [DB:DUCKDB] [CONFIRM] DuckDB database exists at '!db_path!' ^(!_duck_sz! bytes, !_duck_tcnt! table^(s^)^).
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
        echo [INFO] [REUSE] DuckDB database '!db_path!' already has required tables and minimum rows; skipping full re-seed.
        call :set_env_var "LIBSCRIPT_DB_DUCKDB_POPULATED" "1"
    ) else (
        call :quiesce_duckdb_lock_holders "!db_path!"
        echo [INFO] [UPSERT:DUCKDB] Running DuckDB seed_command for '!db_name!': !seed_cmd!
        pushd "!MANIFEST_DIR!"
        cmd.exe /c "!seed_cmd!"
        set "rc=!errorlevel!"
        popd
        if not "!rc!"=="0" exit /b !rc!
        call :set_env_var "LIBSCRIPT_DB_DUCKDB_POPULATED" "1"
    )
)
exit /b 0

:: ## quiesce_duckdb_lock_holders
:: Stops manifest services holding a conflicting lock on the target DuckDB file on Windows.
:quiesce_duckdb_lock_holders
set "_qdl_file=%~1"
if not exist "!_qdl_file!" exit /b 0
set "_qdl_locked=0"
where duckdb >nul 2>nul
if not errorlevel 1 (
    duckdb "!_qdl_file!" -c "SELECT 1;" 2>&1 | findstr /I /C:"Conflicting lock" /C:"Could not set lock" /C:"used by another process" >nul 2>&1
    if not errorlevel 1 set "_qdl_locked=1"
)
if "!_qdl_locked!"=="0" (
    call :find_manifest_duckdb_python
    if not errorlevel 1 if not "!DUCKDB_PY_BIN!"=="" (
        "!DUCKDB_PY_BIN!" -c "import sys,duckdb; con=duckdb.connect(sys.argv[1],read_only=False); con.close()" "!_qdl_file!" 2>&1 | findstr /I /C:"Conflicting lock" /C:"Could not set lock" /C:"used by another process" >nul 2>&1
        if not errorlevel 1 set "_qdl_locked=1"
    )
)
if not "!_qdl_locked!"=="1" exit /b 0
echo [INFO] [DB:DUCKDB] Releasing active service locks on '!_qdl_file!'...
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\init-systems\daemonize.cmd" stop "!JSON_FILE!" >nul 2>&1
)
exit /b 0

:: ## check_duckdb_populated
:: Checks whether all min_tables, required_tables, and min_rows in a DuckDB database file are satisfied on Windows.
:check_duckdb_populated
if "!LIBSCRIPT_FORCE_SEED!"=="1" if not "!db_read_only!"=="1" exit /b 1
if not exist "!db_path!" exit /b 1
set "_cdp_has_req=0"
set "_cdp_min_tbl="
for /f "delims=" %%m in ('echo !db_entry! ^| jq -r ".min_tables // empty" 2^>nul') do set "_cdp_min_tbl=%%m"
if not "!_cdp_min_tbl!"=="" (
    set "_cdp_has_req=1"
    call :query_duckdb_scalar "!db_path!" "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema NOT IN ('information_schema', 'pg_catalog');" "scalar"
    set "_cdp_cnt=!QDS_OUT!"
    if !_cdp_cnt! lss !_cdp_min_tbl! exit /b 1
)
for /f "delims=" %%t in ('echo !db_entry! ^| jq -r ".required_tables[]?" 2^>nul') do (
    set "_cdp_has_req=1"
    set "_cdp_min_r=1"
    for /f "delims=" %%r in ('echo !db_entry! ^| jq -r --arg tbl "%%t" "if (.min_rows | type) == \"number\" then .min_rows elif (.min_rows | type) == \"object\" then (.min_rows[$tbl] // 1) else 1 end" 2^>nul') do set "_cdp_min_r=%%r"
    call :query_duckdb_scalar "!db_path!" "SELECT COUNT(*) FROM \"%%t\";" "scalar"
    set "_cdp_rc=!QDS_OUT!"
    if !_cdp_rc! lss !_cdp_min_r! exit /b 1
    echo [INFO] [DB:DUCKDB] [CONFIRM] Table '!db_name!.%%t' verified ^(!_cdp_rc! rows^).
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
echo [INFO] [DB:VALKEY] Provisioning Valkey/Redis cache endpoint ^(!db_host!:!db_port!/!db_index!^)...
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
    echo [INFO] [DB:VALKEY] [CONFIRM] Valkey/Redis endpoint active at !db_host!:!db_port! ^(db !db_index!^).
) else (
    echo [INFO] [DB:VALKEY] [CREATE] Starting Valkey/Redis on !db_host!:!db_port!...
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
