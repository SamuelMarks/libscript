@echo off
:: # actions.cmd
::
:: ## Overview
:: Unified declarative Machine Learning CLI orchestrator (`train`, `infer`, `serve-ml`, `eval-ml`) on Windows.
:: Executes `.ml` / `.models` / `.training` / `.inference` workflows from `libscript.json` across
:: local hardware (CPU, CUDA, Ollama, vLLM) and cloud accelerators (GCP TPU VM, GCP GPU VM, GKE XPK).
::
:: ## Usage
:: Run via `libscript.cmd train [libscript.json] [--dry-run]` or `libscript.cmd infer [libscript.json] [--dry-run]`.

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

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=train"
shift

set "JSON_FILE="
set "DRY_RUN=0"
set "TARGET_OVERRIDE="
set "BACKEND_OVERRIDE="
set "CMD_OVERRIDE="

:: ## parse_args
:: Parses CLI flags and optional manifest path.
:parse_args
if "%~1"=="" goto :args_done
if /i "%~1"=="--dry-run" (
    set "DRY_RUN=1"
    shift
    goto :parse_args
)
if /i "%~1"=="--target" (
    set "TARGET_OVERRIDE=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--backend" (
    set "BACKEND_OVERRIDE=%~2"
    shift
    shift
    goto :parse_args
)
if /i "%~1"=="--command" (
    set "CMD_OVERRIDE=%~2"
    shift
    shift
    goto :parse_args
)
if exist "%~1" set "JSON_FILE=%~1"
shift
goto :parse_args

:: ## args_done
:: Resolves manifest defaults and dispatches the ML workflow.
:args_done
if "!JSON_FILE!"=="" (
    if exist "libscript.json" set "JSON_FILE=libscript.json"
)

set "MANIFEST_DIR=%CD%"
if not "!JSON_FILE!"=="" (
    for %%P in ("!JSON_FILE!") do set "MANIFEST_DIR=%%~dpP"
    if "!MANIFEST_DIR:~-1!"=="\" set "MANIFEST_DIR=!MANIFEST_DIR:~0,-1!"
)

set "ML_BACKEND=pytorch"
set "ML_TARGET=local"
set "ML_TRAIN_CMD="
set "ML_INFER_CMD="

if not "!JSON_FILE!"=="" (
    if exist "!JSON_FILE!" (
        for /f "delims=" %%b in ('jq -r ".ml.backend // .training.backend // .inference.backend // \"pytorch\"" "!JSON_FILE!" 2^>nul') do set "ML_BACKEND=%%b"
        for /f "delims=" %%t in ('jq -r ".ml.target // .training.target // .inference.target // \"local\"" "!JSON_FILE!" 2^>nul') do set "ML_TARGET=%%t"
        for /f "delims=" %%c in ('jq -r ".ml.train_command // .ml.command // .training.command // empty" "!JSON_FILE!" 2^>nul') do set "ML_TRAIN_CMD=%%c"
        for /f "delims=" %%i in ('jq -r ".ml.infer_command // .ml.serve_command // .inference.command // empty" "!JSON_FILE!" 2^>nul') do set "ML_INFER_CMD=%%i"
    )
)

if not "!TARGET_OVERRIDE!"=="" set "ML_TARGET=!TARGET_OVERRIDE!"
if not "!BACKEND_OVERRIDE!"=="" set "ML_BACKEND=!BACKEND_OVERRIDE!"

set "EXEC_CMD=python train.py"
if /i "!ACTION!"=="train" (
    if not "!ML_TRAIN_CMD!"=="" set "EXEC_CMD=!ML_TRAIN_CMD!"
) else (
    set "EXEC_CMD=python infer.py"
    if not "!ML_INFER_CMD!"=="" set "EXEC_CMD=!ML_INFER_CMD!"
)
if not "!CMD_OVERRIDE!"=="" set "EXEC_CMD=!CMD_OVERRIDE!"

if "!DRY_RUN!"=="1" (
    echo [DRY-RUN] action=!ACTION! target=!ML_TARGET! backend=!ML_BACKEND! command="!EXEC_CMD!"
    exit /b 0
)

if /i "!ML_TARGET!"=="local" (
    pushd "!MANIFEST_DIR!"
    call !EXEC_CMD!
    popd
    exit /b %ERRORLEVEL%
)
if /i "!ML_TARGET!"=="gcp-tpu-vm" (
    set "APP_DIR=!MANIFEST_DIR!"
    set "ML_SCRIPT=!EXEC_CMD!"
    set "WORKLOAD_CMD=!EXEC_CMD!"
    if /i "!ACTION!"=="train" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\deploy.cmd"
    ) else (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ai-serving\deploy.cmd"
    )
    exit /b %ERRORLEVEL%
)
if /i "!ML_TARGET!"=="gcp-gpu-vm" (
    set "APP_DIR=!MANIFEST_DIR!"
    set "WORKLOAD_CMD=!EXEC_CMD!"
    call "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gcp-gpu-vm\deploy.cmd"
    exit /b %ERRORLEVEL%
)
if /i "!ML_TARGET!"=="gke-xpk" (
    set "TRAIN_SCRIPT=!EXEC_CMD!"
    set "WORKLOAD_CMD=!EXEC_CMD!"
    if /i "!ACTION!"=="train" (
        call "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gke-xpk-training\deploy.cmd"
    ) else (
        call "!LIBSCRIPT_ROOT_DIR!\payloads\ai\gke-xpk-inference\deploy.cmd"
    )
    exit /b %ERRORLEVEL%
)

echo [ERROR] Unknown ML target: !ML_TARGET! >&2
exit /b 1
