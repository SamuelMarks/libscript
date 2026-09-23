@echo off
:: # update.cmd
::
:: ## Overview
:: Updates the local package registry with the latest upstream information.
:: 
:: ## Usage
:: Execute this script to refresh registry indices.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%\..\..\.."
)

set "DB_FILE=%LIBSCRIPT_ROOT_DIR%\libscript.sqlite"

where sqlite3 >nul 2>&1
if errorlevel 1 (
    echo Error: sqlite3 is required to update database. 1>&2
    exit /b 1
)

echo Updating database at %DB_FILE%...
sqlite3 "%DB_FILE%" "CREATE TABLE IF NOT EXISTS components (id INTEGER PRIMARY KEY, name TEXT UNIQUE); CREATE TABLE IF NOT EXISTS versions (id INTEGER PRIMARY KEY, component_id INTEGER, version TEXT); CREATE TABLE IF NOT EXISTS files (id INTEGER PRIMARY KEY, version_id INTEGER, url TEXT, checksum TEXT);"

for /d %%C in ("%LIBSCRIPT_ROOT_DIR%\_lib\*\*") do (
    sqlite3 "%DB_FILE%" "INSERT OR IGNORE INTO components (name) VALUES ('%%~nxC');"
)

echo Registry database updated successfully.
exit /b 0
