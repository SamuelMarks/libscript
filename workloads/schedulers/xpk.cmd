@echo off
:: # xpk.cmd
:: ## Overview
:: Tier 4 XPK Gang Scheduler on Windows translating `payload.json` into Google Cloud XPK TPU slice
:: workloads with idempotent deduplication and TFRC zero-cost blocking.
:: ## Usage
:: workloads\schedulers\xpk.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--dry-run] [--live]

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
if /i "%~3"=="--dry-run" set "DRY_RUN=1"

if /i not "!ACTION!"=="compile" (
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
    if not errorlevel 1 (
        set "ML_TARGET=gke-xpk"
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_require_config "%CD%"
        if errorlevel 1 exit /b !errorlevel!
        call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
        if errorlevel 1 exit /b !errorlevel!
    )
)

if /i "!ACTION!"=="compile" (
    jq -r "{scheduler:\"xpk\",workload:.name,tpu_type:(.resources.tpu_topology // \"v5litepod-16\"),num_slices:(.scaling.replicas // 1),xpk_cli_invocation:(\"xpk workload create --workload \" + .name)}" "!TARGET!"
    exit /b !errorlevel!
)

set "WID=xpk-workload"
if exist "!TARGET!" (
    for /f "usebackq delims=" %%N in (`jq -r ".name" "!TARGET!"`) do set "WID=%%N"
) else if not "!TARGET!"=="" (
    set "WID=!TARGET!"
)
set "CLUSTER=%XPK_CLUSTER_NAME%"
if "!CLUSTER!"=="" set "CLUSTER=libscript-tpu-cluster"
set "ZONE=%GCP_ZONE%"
if "!ZONE!"=="" set "ZONE=us-central2-b"

if /i "!ACTION!"=="submit" (
    if not "!DRY_RUN!"=="1" if not "%XPK_CLUSTER_NAME%"=="" if not "%GCP_PROJECT_ID%"=="" (
        where xpk >nul 2>&1
        if not errorlevel 1 (
            xpk workload create --cluster "!CLUSTER!" --workload "!WID!" --project "%GCP_PROJECT_ID%" --zone "!ZONE!" --command "%WORKLOAD_CMD%" 1>&2
        )
    )
)
if /i "!ACTION!"=="destroy" (
    if not "!DRY_RUN!"=="1" if not "%XPK_CLUSTER_NAME%"=="" if not "%GCP_PROJECT_ID%"=="" (
        where xpk >nul 2>&1
        if not errorlevel 1 (
            xpk workload delete --cluster "!CLUSTER!" --workload "!WID!" --project "%GCP_PROJECT_ID%" --zone "!ZONE!" 1>&2
        )
    )
)
jq -n --arg act "!ACTION!" --arg wid "!WID!" "{scheduler:\"xpk\",action:$act,workload:$wid,status:\"ok\"}"
exit /b 0
