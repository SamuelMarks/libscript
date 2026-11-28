@echo off
:: # sync.cmd
:: ## Overview
:: Idempotently synchronizes LibScript and the `libtpu-rs` workspace repository to all Cloud TPU VM workers on Windows.
:: ## Usage
:: sync.cmd [--repo-dir=<dir>] [--dry-run]

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
:: Parses flags and synchronizes repositories to TPU_NAME.
:root_found
set "REPO_DIR=%LIBTPU_RS_REPO_DIR%"
if "!REPO_DIR!"=="" set "REPO_DIR=!LIBSCRIPT_ROOT_DIR!\..\libtpu-rs"
set "DRY_RUN_FLAG=%LIBTPU_RS_DRY_RUN%"
if "!DRY_RUN_FLAG!"=="" set "DRY_RUN_FLAG=0"
goto :parse_args

:: ## parse_args
:: Parses CLI arguments for sync.cmd.
:parse_args
if "%~1"=="" goto :do_sync
set "_a=%~1"
if "!_a:~0,11!"=="--repo-dir=" ( set "REPO_DIR=!_a:~11!" & shift & goto :parse_args )
if /i "!_a!"=="--repo-dir" ( set "REPO_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN_FLAG=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## do_sync
:: Runs gcp-tpu-vm sync-repo for libscript and libtpu-rs across all workers.
:do_sync
if "!DRY_RUN_FLAG!"=="1" (
    echo [SYNC] Verified libtpu-pjrt workspace !REPO_DIR! ^(dry-run^).
    exit /b 0
)
if "%TPU_NAME%"=="" (
    echo [SYNC] Verified local libtpu-pjrt workspace !REPO_DIR!.
    exit /b 0
)
set "_cli=%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd"
call "!_cli!" sync-repo "%TPU_NAME%" "%LIBSCRIPT_ROOT_DIR%" "libscript" --all-workers
if errorlevel 1 exit /b !errorlevel!
if exist "!REPO_DIR!" (
    for %%I in ("!REPO_DIR!") do set "REPO_DIR=%%~fI"
    call "!_cli!" sync-repo "%TPU_NAME%" "!REPO_DIR!" "libtpu-rs" --all-workers
    if errorlevel 1 exit /b !errorlevel!
)
exit /b 0
