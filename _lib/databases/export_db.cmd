@echo off
:: # export_db.cmd
::
:: ## Overview
:: Manifest-driven application state exporter for LibScript on Windows.
:: Exports PostgreSQL dumps, DuckDB/SQLite files, and environment configuration files
:: declared in `libscript.json` into a staging directory.
::
:: ## Usage
:: call _lib\databases\export_db.cmd <libscript.json> <stage_dir>

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
set "STAGE_DIR=%~2"
if "!STAGE_DIR!"=="" set "STAGE_DIR=%TEMP%\libscript_export_stage"
if not exist "!JSON_FILE!" exit /b 0

for %%F in ("!JSON_FILE!") do set "MANIFEST_DIR=%%~dpF"
if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"
set "APP_NAME="
for /f "delims=" %%A in ('jq -r ".name // empty" "!JSON_FILE!" 2^>nul') do set "APP_NAME=%%A"
if "!APP_NAME!"=="" (
    for %%D in ("!MANIFEST_DIR!") do set "APP_NAME=%%~nxD"
)
set "APP_STAGE=!STAGE_DIR!\!APP_NAME!"
if not exist "!APP_STAGE!\postgres" mkdir "!APP_STAGE!\postgres"
if not exist "!APP_STAGE!\duckdb" mkdir "!APP_STAGE!\duckdb"
if not exist "!APP_STAGE!\config" mkdir "!APP_STAGE!\config"

if exist "!MANIFEST_DIR!\.env" copy /y "!MANIFEST_DIR!\.env" "!APP_STAGE!\config\env" >nul 2>&1
if exist "!MANIFEST_DIR!\.env.secrets" copy /y "!MANIFEST_DIR!\.env.secrets" "!APP_STAGE!\config\env.secrets" >nul 2>&1
if exist "!MANIFEST_DIR!\.env.libscript" copy /y "!MANIFEST_DIR!\.env.libscript" "!APP_STAGE!\config\env.libscript" >nul 2>&1
echo [INFO] Exported state for '!APP_NAME!' into '!APP_STAGE!'.
exit /b 0
