@echo off
:: # deprovision_db.cmd
::
:: ## Overview
:: Manifest-driven database deprovisioning engine for LibScript on Windows.
:: Parses `.databases` and `.infrastructure.databases` from `libscript.json` and delegates
:: schema/file removal to `_lib\databases\deprovision_schema.cmd`.
::
:: ## Usage
:: call _lib\databases\deprovision_db.cmd [libscript.json]

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

for %%F in ("!JSON_FILE!") do set "MANIFEST_DIR=%%~dpF"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"

set "JQ_DBS=((.databases // .infrastructure.databases) | if type == \"object\" then to_entries | map(.value + {name: (.value.name // .value.db_name // .key)}) elif type == \"array\" then map(. + {name: (.name // .db_name // .id)}) else [] end)[]?"

for /f "delims=" %%D in ('jq -c "!JQ_DBS!" "!JSON_FILE!" 2^>nul') do (
    set "db_entry=%%D"
    call :deprovision_single_db
)
exit /b 0

:: ## deprovision_single_db
:: Deprovisions a single database entry extracted from libscript.json.
:deprovision_single_db
set "_eng=postgres"
set "_name=app_db"
set "_user=postgres"
set "_path="
for /f "delims=" %%E in ('echo !db_entry! ^| jq -r "(.engine // .type // \"postgres\") | ascii_downcase" 2^>nul') do set "_eng=%%E"
for /f "delims=" %%N in ('echo !db_entry! ^| jq -r ".name // .db_name // \"app_db\"" 2^>nul') do set "_name=%%N"
for /f "delims=" %%U in ('echo !db_entry! ^| jq -r ".user // .username // \"postgres\"" 2^>nul') do set "_user=%%U"
for /f "delims=" %%P in ('echo !db_entry! ^| jq -r ".path // .file // .db_path // empty" 2^>nul') do set "_path=%%P"

if /i "!_eng!"=="duckdb" (
    if "!_path!"=="" set "_path=!MANIFEST_DIR!\data\!_name!.duckdb"
    set "STACK="
    call "!SCRIPT_DIR!\deprovision_schema.cmd" --engine duckdb --schema "!_path!" --user "!_user!"
    for /f "delims=" %%F in ('echo !db_entry! ^| jq -r ".fallback_paths[]? // empty" 2^>nul') do (
        set "_fb_p=%%F"
        set "_fb_win=!_fb_p:/=\!"
        if not "!_fb_win:~1,1!"==":" set "_fb_win=!MANIFEST_DIR!\!_fb_win!"
        set "STACK="
        call "!SCRIPT_DIR!\deprovision_schema.cmd" --engine duckdb --schema "!_fb_win!" --user "!_user!"
    )
    exit /b 0
)
if /i "!_eng!"=="sqlite" (
    if "!_path!"=="" set "_path=!MANIFEST_DIR!\data\!_name!.sqlite"
    set "STACK="
    call "!SCRIPT_DIR!\deprovision_schema.cmd" --engine sqlite --schema "!_path!" --user "!_user!"
    exit /b 0
)
set "STACK="
call "!SCRIPT_DIR!\deprovision_schema.cmd" --engine "!_eng!" --schema "!_name!" --user "!_user!"
for /f "delims=" %%L in ('echo !db_entry! ^| jq -r ".legacy_names[]? // empty" 2^>nul') do (
    set "STACK="
    call "!SCRIPT_DIR!\deprovision_schema.cmd" --engine "!_eng!" --schema "%%L" --user "!_user!"
)
exit /b 0
