@echo off
:: # environ.cmd
::
:: ## Overview
:: Provides utility subroutines to safely save and clear environment variables
:: to/from a file (`:save_environment`, `:clear_environment`), and to parse JSON
:: objects into batch/shell variable assignments (`:libscript_object2key_val`).
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\environ.cmd" :save_environment [out_file]
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\environ.cmd" :libscript_object2key_val "<json>" "SET " """"

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
set "_ENV_FN=%~1"
shift
if /i "!_ENV_FN!"==":save_environment" goto :save_environment
if /i "!_ENV_FN!"=="save_environment" goto :save_environment
if /i "!_ENV_FN!"==":clear_environment" goto :clear_environment
if /i "!_ENV_FN!"=="clear_environment" goto :clear_environment
if /i "!_ENV_FN!"==":libscript_object2key_val" goto :libscript_object2key_val
if /i "!_ENV_FN!"=="libscript_object2key_val" goto :libscript_object2key_val
if /i "!_ENV_FN!"==":load_env" goto :load_env
exit /b 0

:: ## save_environment
:: Exports current environment variables as SET assignments to stdout or a target file.
:save_environment
set "_OUT_FILE=%~1"
for /f "delims=" %%L in ('set') do (
    for /f "tokens=1* delims==" %%A in ("%%L") do (
        if not "%%A"=="" (
            if "!_OUT_FILE!"=="" (
                echo SET "%%A=%%B"
            ) else (
                echo SET "%%A=%%B">> "!_OUT_FILE!"
            )
        )
    )
)
exit /b 0

:: ## clear_environment
:: Resets non-essential user environment variables while preserving system paths.
:clear_environment
set "PATH=%SystemRoot%\system32;%SystemRoot%"
exit /b 0

:: ## load_env
:: Loads SET or KEY=VALUE lines from a specified file into the environment.
:load_env
set "_IN_FILE=%~1"
if exist "!_IN_FILE!" (
    for /f "usebackq tokens=1* delims==" %%A in ("!_IN_FILE!") do (
        set "_K=%%A"
        if not "!_K:~0,1!"=="#" (
            set "%%A=%%~B"
        )
    )
)
exit /b 0

:: ## libscript_object2key_val
:: Formats a JSON object into key-value assignment lines using jq.
:libscript_object2key_val
set "_OBJ=%~1"
set "_PREFIX=%~2"
set "_QUOTE=%~3"
if "!_PREFIX!"=="" set "_PREFIX=SET "
if "!_QUOTE!"=="" set "_QUOTE=\""
where jq >nul 2>&1
if errorlevel 1 exit /b 1
echo !_OBJ! | jq -r --arg prefix "!_PREFIX!" --arg q "!_QUOTE!" "to_entries[] | ($prefix + .key + \"=\" + $q + (.value | tostring) + $q)"
exit /b 0
