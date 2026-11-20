@echo off
:: # tpu_vm.cmd
:: ## Overview
:: Tier 4 Cloud TPU VM Slice Scheduler on Windows coordinating tree-hashed `--all-workers` sync,
:: `/dev/shm` uv virtualenvs, TFRC guardrails, and multi-host lockstep execution.
:: ## Usage
:: payloads\schedulers\tpu_vm.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--dry-run] [--live]

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
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "ACTION=%~1"
set "TARGET=%~2"
if "!ACTION!"=="" set "ACTION=compile"
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "LIVE_EXEC=0"
if "%LIBSCRIPT_SCHEDULER_LIVE%"=="1" set "LIVE_EXEC=1"
set "BACKEND=%TPU_BACKEND%"
if "!BACKEND!"=="" set "BACKEND=jax_native"

shift
shift
goto :parse_args

:: ## parse_args
:: Parses flags for tpu_vm.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--live" ( set "LIVE_EXEC=1" & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--backend=" ( set "BACKEND=!_a:~10!" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Validates TFRC policy if active and dispatches TPU scheduler action.
:args_done
call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_require_config "%CD%"
    if errorlevel 1 exit /b !errorlevel!
    call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
    if errorlevel 1 exit /b !errorlevel!
)

set "WID=tpu-workload"
if exist "!TARGET!" (
    for /f "usebackq delims=" %%N in (`jq -r ".name // \"tpu-workload\"" "!TARGET!"`) do set "WID=%%N"
) else if not "!TARGET!"=="" (
    set "WID=!TARGET!"
)
set "TPU_NODE=%TPU_NAME%"
if "!TPU_NODE!"=="" set "TPU_NODE=!WID!-tpu"
set "TPU_SKU=%TPU_ACCELERATOR_TYPE%"
if "!TPU_SKU!"=="" set "TPU_SKU=v4-8"
set "CMD_STR=%WORKLOAD_CMD%"
if "!CMD_STR!"=="" set "CMD_STR=python train.py"

if /i "!ACTION!"=="compile" (
    jq -n --arg wid "!WID!" --arg node "!TPU_NODE!" --arg sku "!TPU_SKU!" --arg backend "!BACKEND!" --arg cmd "!CMD_STR!" "{scheduler:\"tpu_vm\",workload_id:$wid,tpu_name:$node,accelerator_type:$sku,backend:$backend,shm_venv_root:\"/dev/shm/libscript-tpu\",sync_mode:\"tree-hash-all-workers\",command:$cmd}"
    exit /b 0
)

set "TPU_CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd"
if /i "!ACTION!"=="submit" (
    if not "!DRY_RUN!"=="1" if not "%GCP_PROJECT_ID%"=="" if not "%TPU_ZONE%"=="" (
        call "!TPU_CLI!" create "!TPU_NODE!" 1>&2
        if errorlevel 1 exit /b !errorlevel!
        call "!TPU_CLI!" wait-ready "!TPU_NODE!" 1>&2
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tpu_matrix.cmd" :libscript_tpu_bootstrap_remote "!TPU_NODE!" "%APP_DIR%" 1>&2
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "!TPU_NODE!" "!BACKEND!" "!CMD_STR!" "%TEMP%\!WID!_logs" 1>&2
    )
    jq -n --arg wid "!WID!" --arg node "!TPU_NODE!" "{scheduler:\"tpu_vm\",action:\"submit\",workload:$wid,tpu_name:$node,status:\"ok\"}"
    exit /b 0
)
if /i "!ACTION!"=="destroy" (
    if not "!DRY_RUN!"=="1" if not "%GCP_PROJECT_ID%"=="" if not "%TPU_ZONE%"=="" (
        call "!TPU_CLI!" delete "!TPU_NODE!" 1>&2
    )
    jq -n --arg wid "!WID!" --arg node "!TPU_NODE!" "{scheduler:\"tpu_vm\",action:\"destroy\",workload:$wid,tpu_name:$node,status:\"ok\"}"
    exit /b 0
)
jq -n --arg wid "!WID!" --arg act "!ACTION!" "{scheduler:\"tpu_vm\",action:$act,workload:$wid,status:\"ok\"}"
exit /b 0
