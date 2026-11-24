@echo off
:: # provision.cmd
:: ## Overview
:: Provisions a TFRC-guarded Cloud TPU VM slice, arms auto-TTL, and bootstraps remote tools for `gemma-4-sql` on Windows.
:: ## Usage
:: provision.cmd [--tfrc-config=<path>] [--repo-dir=<dir>] [--dry-run]

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
:: Parses flags and provisions the target Cloud TPU VM slice.
:root_found
set "REPO_DIR=%GEMMA_4_SQL_REPO_DIR%"
if "!REPO_DIR!"=="" set "REPO_DIR=%CD%"
set "DRY_RUN_FLAG=%GEMMA_4_SQL_DRY_RUN%"
if "!DRY_RUN_FLAG!"=="" set "DRY_RUN_FLAG=0"
goto :parse_args

:: ## parse_args
:: Parses CLI options for provision.cmd.
:parse_args
if "%~1"=="" goto :do_provision
set "_a=%~1"
if "!_a:~0,14!"=="--tfrc-config=" ( set "TFRC_CONFIG=!_a:~14!" & set "TFRC_STRICT=1" & shift & goto :parse_args )
if /i "!_a!"=="--tfrc-config" ( set "TFRC_CONFIG=%~2" & set "TFRC_STRICT=1" & shift & shift & goto :parse_args )
if "!_a:~0,11!"=="--repo-dir=" ( set "REPO_DIR=!_a:~11!" & shift & goto :parse_args )
if /i "!_a!"=="--repo-dir" ( set "REPO_DIR=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN_FLAG=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## do_provision
:: Validates TFRC config and creates/bootstraps the Cloud TPU VM slice.
:do_provision
for %%I in ("!REPO_DIR!") do set "REPO_DIR=%%~fI"
call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_require_config "!REPO_DIR!"
    if errorlevel 1 exit /b !errorlevel!
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
    if errorlevel 1 exit /b !errorlevel!
    if "%GCP_PROJECT_ID%"=="" for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "GCP_PROJECT_ID=%%P"
    if "%TPU_ZONE%"=="" for /f "usebackq delims=" %%Z in (`jq -r ".grants[0].zone" "!TFRC_CONFIG!"`) do set "TPU_ZONE=%%Z"
    if "%TPU_ACCELERATOR_TYPE%"=="" for /f "usebackq delims=" %%A in (`jq -r ".grants[0].accelerator_types[0]" "!TFRC_CONFIG!"`) do set "TPU_ACCELERATOR_TYPE=%%A"
    if "%TPU_SCHEDULING_TYPE%"=="" for /f "usebackq delims=" %%S in (`jq -r ".grants[0].scheduling_tiers[0]" "!TFRC_CONFIG!"`) do set "TPU_SCHEDULING_TYPE=%%S"
)
if "%TPU_NAME%"=="" set "TPU_NAME=gemma-tfrc-node"
if "!DRY_RUN_FLAG!"=="1" (
    echo [INFO] [DRY-RUN] Validated gemma-4-sql TPU provisioning plan for !TPU_NAME!.
    exit /b 0
)
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_ensure_host_tools "1"
set "_cli=%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd"
call "!_cli!" create "!TPU_NAME!"
if errorlevel 1 exit /b !errorlevel!
call "!_cli!" wait-ready "!TPU_NAME!"
if errorlevel 1 exit /b !errorlevel!
set "_ttl=%TFRC_MAX_TTL_MINUTES%"
if "!_ttl!"=="" set "_ttl=180"
call "!_cli!" arm-ttl "!TPU_NAME!" --minutes "!_ttl!"
if errorlevel 1 exit /b !errorlevel!
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_bootstrap_remote "!TPU_NAME!" "!REPO_DIR!"
exit /b !errorlevel!
