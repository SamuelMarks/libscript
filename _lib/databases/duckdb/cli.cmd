@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface for DuckDB on Windows.
::
:: ## Usage
:: Wraps the duckdb executable. Run `libscript databases/duckdb execute <db> <query>` or `repl <db>`.

setlocal EnableDelayedExpansion

set "LOG_CMD=%~dp0..\..\..\_common\log.cmd"

if "%~1"=="--help" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)

where duckdb >nul 2>nul
if %errorlevel% neq 0 (
    set "DUCKDB_PATH=%LIBSCRIPT_ROOT_DIR%\installed\duckdb\bin\duckdb.exe"
    if exist "!DUCKDB_PATH!" (
        set "PATH=%LIBSCRIPT_ROOT_DIR%\installed\duckdb\bin;%PATH%"
    ) else (
        call "%LOG_CMD%" :log_error "duckdb not found. Please install the databases/duckdb component first."
        exit /b 1
    )
)

set "ACTION=%~1"

if "%ACTION%"=="execute" goto :execute
if "%ACTION%"=="repl" goto :repl

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%. Supported: execute, repl."
exit /b 1

:execute
set "DB_PATH=%~2"
if "%DB_PATH%"=="" set "DB_PATH=:memory:"
set "QUERY=%~3"
if "%QUERY%"=="" (
    call "%LOG_CMD%" :log_error "Usage: duckdb execute <db_path> <query>"
    exit /b 1
)

call "%LOG_CMD%" :log_info "Executing query on DuckDB %DB_PATH%..."
duckdb "%DB_PATH%" -c "%QUERY%"
exit /b 0

:repl
set "DB_PATH=%~2"
if "%DB_PATH%"=="" set "DB_PATH=:memory:"
call "%LOG_CMD%" :log_info "Starting DuckDB REPL on %DB_PATH%..."
duckdb "%DB_PATH%"
exit /b 0
