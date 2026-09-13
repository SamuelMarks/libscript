@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface for DuckDB on Windows.
::
:: ## Usage
:: Run `libscript databases/duckdb [args...]`. Delegates to component core.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=duckdb"

set "ACTION=%~1"

if "%ACTION%"=="execute" goto :execute
if "%ACTION%"=="repl" goto :repl

call "%~dp0\..\..\_common\component_core.cmd" %*
exit /b %errorlevel%

:: ## execute
:: Executes execute functionality.
:execute
set "DB_PATH=%~2"
if "%DB_PATH%"=="" set "DB_PATH=:memory:"
set "QUERY=%~3"
if "%QUERY%"=="" (
    echo Usage: duckdb execute ^<db_path^> ^<query^> >&2
    exit /b 1
)

duckdb "%DB_PATH%" -c "%QUERY%"
exit /b 0

:: ## repl
:: Executes repl functionality.
:repl
set "DB_PATH=%~2"
if "%DB_PATH%"=="" set "DB_PATH=:memory:"
duckdb "%DB_PATH%"
exit /b 0
