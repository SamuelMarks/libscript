@echo off
:: # actions.cmd
:: ## Overview
:: Unified declarative Machine Learning CLI orchestrator (train, infer, serve-ml, eval-ml, benchmark-ml) on Windows with TFRC zero-cost 7-backend evaluation support.
:: ## Usage
:: libscript.cmd <train|infer|serve-ml|eval-ml|benchmark-ml> [libscript.json] ["--tfrc-config=<path>"] ["--backends=<csv|all>"] [--dry-run]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=train"
shift

set "JSON_FILE="
set "DRY_RUN_FLAG=0"
set "TARGET_OVERRIDE="
set "BACKEND_OVERRIDE="
set "BACKENDS_MATRIX="
set "WORKLOADS_CSV="
set "CMD_OVERRIDE="
set "CMD_TEMPLATE="
set "MODEL_OVERRIDE="
set "FRESH_VM=0"
set "RESUME_FLAG=1"
goto :parse_args

:: ## parse_args
:: Parses CLI flags and optional manifest path supporting both quoted --key=val and space-separated tokens.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--dry-run" ( set "DRY_RUN_FLAG=1" & shift & goto :parse_args )
if /i "!_a!"=="--tfrc-only" ( set "TFRC_STRICT=1" & shift & goto :parse_args )
if /i "!_a!"=="--fresh-vm-per-backend" ( set "FRESH_VM=1" & set "TPU_FRESH_VM_PER_BACKEND=1" & shift & goto :parse_args )
if /i "!_a!"=="--resume" ( set "RESUME_FLAG=1" & shift & goto :parse_args )
if /i "!_a!"=="--no-resume" ( set "RESUME_FLAG=0" & shift & goto :parse_args )
if "!_a:~0,14!"=="--tfrc-config=" ( set "TFRC_CONFIG=!_a:~14!" & set "TFRC_STRICT=1" & shift & goto :parse_args )
if /i "!_a!"=="--tfrc-config" ( set "TFRC_CONFIG=%~2" & set "TFRC_STRICT=1" & shift & shift & goto :parse_args )
if "!_a:~0,9!"=="--target=" ( set "TARGET_OVERRIDE=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--target" ( set "TARGET_OVERRIDE=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,10!"=="--backend=" ( set "BACKEND_OVERRIDE=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--backend" ( set "BACKEND_OVERRIDE=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,11!"=="--backends=" ( set "BACKENDS_MATRIX=!_a:~11!" & shift & goto :parse_args )
if /i "!_a!"=="--backends" ( set "BACKENDS_MATRIX=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,12!"=="--workloads=" ( set "WORKLOADS_CSV=!_a:~12!" & shift & goto :parse_args )
if /i "!_a!"=="--workloads" ( set "WORKLOADS_CSV=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,12!"=="--subsuites=" ( set "WORKLOADS_CSV=!_a:~12!" & shift & goto :parse_args )
if /i "!_a!"=="--subsuites" ( set "WORKLOADS_CSV=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,8!"=="--model=" ( set "MODEL_OVERRIDE=!_a:~8!" & shift & goto :parse_args )
if /i "!_a!"=="--model" ( set "MODEL_OVERRIDE=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,19!"=="--command-template=" ( set "CMD_TEMPLATE=!_a:~19!" & shift & goto :parse_args )
if /i "!_a!"=="--command-template" ( set "CMD_TEMPLATE=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,10!"=="--command=" ( set "CMD_OVERRIDE=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--command" ( set "CMD_OVERRIDE=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,18!"=="--max-ttl-minutes=" ( set "TFRC_MAX_TTL_MINUTES=!_a:~18!" & shift & goto :parse_args )
if /i "!_a!"=="--max-ttl-minutes" ( set "TFRC_MAX_TTL_MINUTES=%~2" & shift & shift & goto :parse_args )
if "!_a:~0,13!"=="--gcs-bucket=" ( set "GCS_BUCKET=!_a:~13!" & set "TFRC_STORAGE_MODE=same_region_gcs" & set "TFRC_EXPLICIT_GCS_BUCKET=1" & shift & goto :parse_args )
if /i "!_a!"=="--gcs-bucket" ( set "GCS_BUCKET=%~2" & set "TFRC_STORAGE_MODE=same_region_gcs" & set "TFRC_EXPLICIT_GCS_BUCKET=1" & shift & shift & goto :parse_args )
if exist "!_a!" set "JSON_FILE=!_a!"
shift
goto :parse_args

:: ## args_done
:: Resolves manifest defaults, validates TFRC guardrails, and dispatches the ML workflow.
:args_done
if "!JSON_FILE!"=="" if exist "libscript.json" set "JSON_FILE=libscript.json"
set "MANIFEST_DIR=%CD%"
if not "!JSON_FILE!"=="" (
    for %%P in ("!JSON_FILE!") do set "MANIFEST_DIR=%%~dpP"
    if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"
)

set "ML_BACKEND=pytorch"
set "ML_TARGET=local"
set "ML_MODEL=google/gemma-4-E4B"
set "ML_TRAIN_CMD="
set "ML_INFER_CMD="
set "ML_EVAL_CMD="
set "ML_BENCH_CMD="

if not "!JSON_FILE!"=="" if exist "!JSON_FILE!" (
    for /f "usebackq delims=" %%b in (`jq -r ".ml.backend // .training.backend // .inference.backend // \"pytorch\"" "!JSON_FILE!" 2^>nul`) do set "ML_BACKEND=%%b"
    for /f "usebackq delims=" %%t in (`jq -r ".ml.target // .training.target // .inference.target // \"local\"" "!JSON_FILE!" 2^>nul`) do set "ML_TARGET=%%t"
    for /f "usebackq delims=" %%m in (`jq -r ".ml.model // \"google/gemma-4-E4B\"" "!JSON_FILE!" 2^>nul`) do set "ML_MODEL=%%m"
    for /f "usebackq delims=" %%c in (`jq -r ".ml.train_command // .ml.command // .training.command // empty" "!JSON_FILE!" 2^>nul`) do set "ML_TRAIN_CMD=%%c"
    for /f "usebackq delims=" %%i in (`jq -r ".ml.infer_command // .ml.serve_command // .inference.command // empty" "!JSON_FILE!" 2^>nul`) do set "ML_INFER_CMD=%%i"
    for /f "usebackq delims=" %%e in (`jq -r ".ml.eval_command // empty" "!JSON_FILE!" 2^>nul`) do set "ML_EVAL_CMD=%%e"
    for /f "usebackq delims=" %%k in (`jq -r ".ml.benchmark_command // empty" "!JSON_FILE!" 2^>nul`) do set "ML_BENCH_CMD=%%k"
    for /f "usebackq delims=" %%o in (`jq -r "if .ml.tfrc_only == true then \"1\" else empty end" "!JSON_FILE!" 2^>nul`) do set "TFRC_STRICT=%%o"
    if "!TFRC_CONFIG!"=="" (
        for /f "usebackq delims=" %%f in (`jq -r ".ml.tfrc_config // empty" "!JSON_FILE!" 2^>nul`) do set "TFRC_CONFIG=%%f"
    )
    if "!TPU_NAME!"=="" for /f "usebackq delims=" %%n in (`jq -r ".ml.tpu_name // empty" "!JSON_FILE!" 2^>nul`) do set "TPU_NAME=%%n"
    if "!TPU_ZONE!"=="" for /f "usebackq delims=" %%z in (`jq -r ".ml.tpu_zone // empty" "!JSON_FILE!" 2^>nul`) do set "TPU_ZONE=%%z"
    if "!TPU_ACCELERATOR_TYPE!"=="" for /f "usebackq delims=" %%s in (`jq -r ".ml.tpu_type // empty" "!JSON_FILE!" 2^>nul`) do set "TPU_ACCELERATOR_TYPE=%%s"
    if "!TPU_SCHEDULING_TYPE!"=="" for /f "usebackq delims=" %%y in (`jq -r ".ml.tpu_scheduling_type // empty" "!JSON_FILE!" 2^>nul`) do set "TPU_SCHEDULING_TYPE=%%y"
    if "!GCP_PROJECT_ID!"=="" for /f "usebackq delims=" %%p in (`jq -r ".ml.gcp_project // empty" "!JSON_FILE!" 2^>nul`) do set "GCP_PROJECT_ID=%%p"
)

if not "!TARGET_OVERRIDE!"=="" set "ML_TARGET=!TARGET_OVERRIDE!"
if not "!BACKEND_OVERRIDE!"=="" set "ML_BACKEND=!BACKEND_OVERRIDE!"
if not "!MODEL_OVERRIDE!"=="" set "ML_MODEL=!MODEL_OVERRIDE!"

call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_require_config "!MANIFEST_DIR!"
    if errorlevel 1 exit /b !errorlevel!
    call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
    if errorlevel 1 exit /b !errorlevel!
    if not "!GCS_BUCKET!"=="" if not "!TPU_ZONE!"=="" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_verify_gcs_bucket "!GCS_BUCKET!" "!TPU_ZONE!"
        if errorlevel 1 exit /b !errorlevel!
    )
)

if /i "!ACTION!"=="benchmark-ml" goto :dispatch_matrix
if not "!BACKENDS_MATRIX!"=="" goto :dispatch_matrix
goto :standard_ml

:: ## dispatch_matrix
:: Routes multi-backend ML benchmark campaigns to experiment_cloud.cmd tpu_matrix or local benchmark_experiments.cmd.
:dispatch_matrix
set "_mflags=\"--repo-dir=!MANIFEST_DIR!\" \"--model=!ML_MODEL!\""
if not "!TFRC_CONFIG!"=="" set "_mflags=!_mflags! \"--tfrc-config=!TFRC_CONFIG!\""
if not "!BACKENDS_MATRIX!"=="" set "_mflags=!_mflags! \"--backends=!BACKENDS_MATRIX!\""
if not "!WORKLOADS_CSV!"=="" set "_mflags=!_mflags! \"--subsuites=!WORKLOADS_CSV!\""
if not "!CMD_TEMPLATE!"=="" set "_mflags=!_mflags! \"--command-template=!CMD_TEMPLATE!\""
if "!FRESH_VM!"=="1" set "_mflags=!_mflags! --fresh-vm-per-backend"
if "!RESUME_FLAG!"=="0" set "_mflags=!_mflags! --no-resume"
if "!DRY_RUN_FLAG!"=="1" set "_mflags=!_mflags! --dry-run"
call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if errorlevel 1 if /i "!ML_TARGET!"=="local" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\gemma-tpu-suite\benchmark_experiments.cmd" --local-exec !_mflags!
    exit /b !errorlevel!
)
call "!LIBSCRIPT_ROOT_DIR!\_lib\cloud\core\experiment_cloud.cmd" tpu_matrix !_mflags!
exit /b !errorlevel!

:: ## standard_ml
:: Executes single-backend train, infer, serve-ml, or eval-ml workflows.
:standard_ml
set "EXEC_CMD=python train.py"
if /i "!ACTION!"=="train" (
    if not "!ML_TRAIN_CMD!"=="" set "EXEC_CMD=!ML_TRAIN_CMD!"
) else if /i "!ACTION!"=="eval-ml" (
    set "EXEC_CMD=python eval.py"
    if not "!ML_EVAL_CMD!"=="" set "EXEC_CMD=!ML_EVAL_CMD!"
) else (
    set "EXEC_CMD=python infer.py"
    if not "!ML_INFER_CMD!"=="" set "EXEC_CMD=!ML_INFER_CMD!"
)
if not "!CMD_OVERRIDE!"=="" set "EXEC_CMD=!CMD_OVERRIDE!"

if "!DRY_RUN_FLAG!"=="1" (
    echo [DRY-RUN] action=!ACTION! target=!ML_TARGET! backend=!ML_BACKEND! command="!EXEC_CMD!"
    exit /b 0
)

if /i "!ML_TARGET!"=="local" (
    pushd "!MANIFEST_DIR!"
    call !EXEC_CMD!
    set "_lrc=!errorlevel!"
    popd
    exit /b !_lrc!
)
if /i "!ML_TARGET!"=="gcp-tpu-vm" goto :run_tpu_vm
if /i "!ML_TARGET!"=="tpu-vm" goto :run_tpu_vm
if /i "!ML_TARGET!"=="gcp-gpu-vm" (
    set "APP_DIR=!MANIFEST_DIR!"
    set "WORKLOAD_CMD=!EXEC_CMD!"
    call "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gcp-gpu-vm\deploy.cmd"
    exit /b !errorlevel!
)
if /i "!ML_TARGET!"=="gke-xpk" goto :run_xpk
if /i "!ML_TARGET!"=="xpk" goto :run_xpk
if /i "!ML_TARGET!"=="kubernetes" (
    set "WORKLOAD_CMD=!EXEC_CMD!"
    call "!LIBSCRIPT_ROOT_DIR!\payloads\engine.cmd" submit "!LIBSCRIPT_ROOT_DIR!\payloads\ai\vllm\payload.json" --scheduler=kubernetes
    exit /b !errorlevel!
)
echo [ERROR] Unknown ML target: !ML_TARGET! >&2
exit /b 1

:: ## run_tpu_vm
:: Dispatches TPU VM workload submission through payloads\engine.cmd.
:run_tpu_vm
set "APP_DIR=!MANIFEST_DIR!"
set "ML_SCRIPT=!EXEC_CMD!"
set "WORKLOAD_CMD=!EXEC_CMD!"
set "TPU_BACKEND=!ML_BACKEND!"
call "!LIBSCRIPT_ROOT_DIR!\payloads\engine.cmd" submit "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gcp-tpu-vm\payload.json" --scheduler=tpu_vm
exit /b !errorlevel!

:: ## run_xpk
:: Dispatches XPK workload submission through payloads\engine.cmd.
:run_xpk
set "TRAIN_SCRIPT=!EXEC_CMD!"
set "WORKLOAD_CMD=!EXEC_CMD!"
if /i "!ACTION!"=="train" (
    call "!LIBSCRIPT_ROOT_DIR!\payloads\engine.cmd" submit "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gke-xpk-training\payload.json" --scheduler=xpk
) else (
    call "!LIBSCRIPT_ROOT_DIR!\payloads\engine.cmd" submit "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gke-xpk-inference\payload.json" --scheduler=xpk
)
exit /b !errorlevel!
