@echo off
:: # settings_updater.cmd
::
:: ## Overview
:: Provides utilities for emitting configuration or environment settings (`:lang_export`)
:: and updating JSON configuration files (`:update_json`) across `cmd`, `sh`, and `sqlite`.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\settings_updater.cmd" :lang_export <lang> <key> <val>
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\settings_updater.cmd" :update_json <file> <key> <val>

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

if "%~1"=="" exit /b 0
if /i "%~1"==":lang_export" (
    call :lang_export "%~2" "%~3" "%~4"
    exit /b !errorlevel!
)
if /i "%~1"=="lang_export" (
    call :lang_export "%~2" "%~3" "%~4"
    exit /b !errorlevel!
)
if /i "%~1"==":update_json" (
    call :update_json "%~2" "%~3" "%~4"
    exit /b !errorlevel!
)
call :lang_export "%~1" "%~2" "%~3"
exit /b !errorlevel!

:: ## lang_export
:: Emits a key-value assignment formatted for cmd, sh, or sqlite.
:lang_export
set "_LANG=%~1"
set "_KEY=%~2"
set "_VAL=%~3"
set "_IS_DIGIT=1"
if "!_VAL!"=="" set "_IS_DIGIT=0"
for /f "delims=0123456789" %%D in ("!_VAL!") do set "_IS_DIGIT=0"

if /i "!_LANG!"=="cmd" (
    if "!_IS_DIGIT!"=="1" (
        echo SET !_KEY!=!_VAL!
    ) else (
        echo SET !_KEY!="!_VAL!"
    )
    exit /b 0
)
if /i "!_LANG!"=="sh" (
    if "!_IS_DIGIT!"=="1" (
        echo export !_KEY!=!_VAL!
    ) else (
        echo export !_KEY!='%_VAL%'
    )
    exit /b 0
)
if /i "!_LANG!"=="sqlite" (
    if "!sql3!"=="1" if not "!db_file!"=="" (
        sqlite3 "!db_file!" "CREATE TABLE IF NOT EXISTS T (key TEXT UNIQUE, val TEXT); INSERT OR REPLACE INTO T (key, val) VALUES ('!_KEY!', '!_VAL!');"
    )
    exit /b 0
)
echo Unsupported language: !_LANG! 1>&2
exit /b 5

:: ## update_json
:: Safely updates a top-level key in a JSON file using jq.
:update_json
set "_JFILE=%~1"
set "_JKEY=%~2"
set "_JVAL=%~3"
if not exist "!_JFILE!" echo {}> "!_JFILE!"
where jq >nul 2>&1
if errorlevel 1 exit /b 1
jq --arg k "!_JKEY!" --arg v "!_JVAL!" ".[$k] = $v" "!_JFILE!" > "!_JFILE!.tmp"
move /y "!_JFILE!.tmp" "!_JFILE!" >nul
exit /b 0
