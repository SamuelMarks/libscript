@echo off
:: # teardown.cmd
:: ## Overview
:: Deletes the Cloud TPU VM + Queued Resource and executes a post-flight TFRC orphan audit on Windows.
:: ## Usage
:: teardown.cmd [--tfrc-config=<path>] [--dry-run]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Parses flags and tears down TPU_NAME.
:root_found
set "DRY_RUN_FLAG=%GEMMA_4_SQL_DRY_RUN%"
if "!DRY_RUN_FLAG!"=="" set "DRY_RUN_FLAG=0"
goto :parse_args

:: ## parse_args
:: Parses CLI options for teardown.cmd.
:parse_args
if "%~1"=="" goto :do_teardown
set "_a=%~1"
if "!_a:~0,14!"=="--tfrc-config=" ( set "TFRC_CONFIG=!_a:~14!" & set "TFRC_STRICT=1" & shift & goto :parse_args )
if /i "!_a!"=="--tfrc-config" ( set "TFRC_CONFIG=%~2" & set "TFRC_STRICT=1" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN_FLAG=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## do_teardown
:: Deletes TPU_NAME and runs post-flight orphan verification when TFRC is active.
:do_teardown
if "!DRY_RUN_FLAG!"=="1" (
    echo [INFO] [TEARDOWN] Dry-run verified for %TPU_NAME%.
    exit /b 0
)
if "%TPU_NAME%"=="" (
    echo [INFO] [TEARDOWN] No active remote TPU VM slice to tear down.
    exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd" delete "%TPU_NAME%"
if errorlevel 1 exit /b !errorlevel!
call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 if not "%TPU_ZONE%"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_postflight_audit "%GCP_PROJECT_ID%" "%TPU_ZONE%" "%TPU_NAME%"
    if errorlevel 1 exit /b !errorlevel!
)
exit /b 0
