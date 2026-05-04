@echo off
setlocal EnableDelayedExpansion
set "query=%~2"
set "DB_FILE=!LIBSCRIPT_ROOT_DIR!\libscript.sqlite"
if "!LIBSCRIPT_ROOT_DIR!"=="" set "DB_FILE=%SCRIPT_DIR%libscript.sqlite"
if not exist "!DB_FILE!" (
    echo Error: Database not found. Run update-db first. 1>&2
    exit /b 1
)
sqlite3 -column -header "!DB_FILE!" "SELECT c.name, v.version, f.url, f.checksum FROM components c LEFT JOIN versions v ON c.id = v.component_id LEFT JOIN files f ON v.id = f.version_id WHERE c.name LIKE '%%!query!%%' OR v.version LIKE '%%!query!%%'"
exit /b !errorlevel!
