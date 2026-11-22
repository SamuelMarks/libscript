@echo off
:: # benchmark_experiments.cmd
:: ## Overview
:: Master idempotent 7-backend TFRC TPU benchmark orchestrator on Windows routing E0-E4 locally or remotely across Cloud TPU VM --worker=all with per-cell result streaming.
:: ## Usage
:: benchmark_experiments.cmd ["--tfrc-config=<path>"] ["--repo-dir=<dir>"] ["--results-dir=<dir>"] ["--backends=<csv|all>"] ["--subsuites=E0,E1,E2,E3,E4"]

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
if "!d!"=="" exit /b 1
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
if "%GEMMA_TPU_SUITE_REPO_DIR%"=="" set "GEMMA_TPU_SUITE_REPO_DIR=%CD%"
if "%GEMMA_TPU_SUITE_RESULTS_DIR%"=="" set "GEMMA_TPU_SUITE_RESULTS_DIR=%LIBSCRIPT_ROOT_DIR%\build\experiment_results\gemma_tpu"
if "%GEMMA_TPU_SUITE_MODEL%"=="" set "GEMMA_TPU_SUITE_MODEL=google/gemma-4-E4B"
if "%GEMMA_TPU_SUITE_BACKENDS%"=="" set "GEMMA_TPU_SUITE_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
if "%GEMMA_TPU_SUITE_SUBSUITES%"=="" set "GEMMA_TPU_SUITE_SUBSUITES=E0,E1,E2,E3,E4"
if "%GEMMA_TPU_SUITE_WARMUP%"=="" set "GEMMA_TPU_SUITE_WARMUP=2"
if "%GEMMA_TPU_SUITE_TRIALS%"=="" set "GEMMA_TPU_SUITE_TRIALS=5"
if "%GEMMA_TPU_SUITE_REQUIRE_HBM%"=="" set "GEMMA_TPU_SUITE_REQUIRE_HBM=1"
if "%GEMMA_TPU_SUITE_RESUME%"=="" set "GEMMA_TPU_SUITE_RESUME=1"
if "%GEMMA_TPU_SUITE_LOCAL_EXEC%"=="" set "GEMMA_TPU_SUITE_LOCAL_EXEC=0"
if "%GEMMA_TPU_SUITE_DRY_RUN%"=="" set "GEMMA_TPU_SUITE_DRY_RUN=0"
goto :parse_args

:: ## parse_args
:: Parses quoted or space-separated CLI flags for benchmark_experiments.cmd.
:parse_args
if "%~1"=="" goto :after_args
set "_arg=%~1"
if /i "!_arg!"=="--help" goto :show_help
if /i "!_arg!"=="-h" goto :show_help
if /i "!_arg!"=="experiments" ( shift & goto :parse_args )
if /i "!_arg!"=="benchmark-matrix" ( shift & goto :parse_args )
if "!_arg:~0,11!"=="--repo-dir=" ( set "GEMMA_TPU_SUITE_REPO_DIR=!_arg:~11!" & shift & goto :parse_args )
if /i "!_arg!"=="--repo-dir" ( set "GEMMA_TPU_SUITE_REPO_DIR=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,14!"=="--results-dir=" ( set "GEMMA_TPU_SUITE_RESULTS_DIR=!_arg:~14!" & shift & goto :parse_args )
if /i "!_arg!"=="--results-dir" ( set "GEMMA_TPU_SUITE_RESULTS_DIR=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,13!"=="--output-dir=" ( set "GEMMA_TPU_SUITE_RESULTS_DIR=!_arg:~13!" & shift & goto :parse_args )
if /i "!_arg!"=="--output-dir" ( set "GEMMA_TPU_SUITE_RESULTS_DIR=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,14!"=="--tfrc-config=" ( set "TFRC_CONFIG=!_arg:~14!" & shift & goto :parse_args )
if /i "!_arg!"=="--tfrc-config" ( set "TFRC_CONFIG=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,8!"=="--model=" ( set "GEMMA_TPU_SUITE_MODEL=!_arg:~8!" & shift & goto :parse_args )
if /i "!_arg!"=="--model" ( set "GEMMA_TPU_SUITE_MODEL=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,11!"=="--backends=" ( set "GEMMA_TPU_SUITE_BACKENDS=!_arg:~11!" & shift & goto :parse_args )
if /i "!_arg!"=="--backends" ( set "GEMMA_TPU_SUITE_BACKENDS=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,12!"=="--subsuites=" ( set "GEMMA_TPU_SUITE_SUBSUITES=!_arg:~12!" & shift & goto :parse_args )
if /i "!_arg!"=="--subsuites" ( set "GEMMA_TPU_SUITE_SUBSUITES=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,19!"=="--command-template=" ( set "GEMMA_TPU_SUITE_COMMAND_TEMPLATE=!_arg:~19!" & shift & goto :parse_args )
if /i "!_arg!"=="--command-template" ( set "GEMMA_TPU_SUITE_COMMAND_TEMPLATE=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,9!"=="--warmup=" ( set "GEMMA_TPU_SUITE_WARMUP=!_arg:~9!" & shift & goto :parse_args )
if /i "!_arg!"=="--warmup" ( set "GEMMA_TPU_SUITE_WARMUP=%~2" & shift & shift & goto :parse_args )
if "!_arg:~0,9!"=="--trials=" ( set "GEMMA_TPU_SUITE_TRIALS=!_arg:~9!" & shift & goto :parse_args )
if /i "!_arg!"=="--trials" ( set "GEMMA_TPU_SUITE_TRIALS=%~2" & shift & shift & goto :parse_args )
if /i "!_arg!"=="--fresh-vm-per-backend" ( set "TPU_FRESH_VM_PER_BACKEND=1" & shift & goto :parse_args )
if /i "!_arg!"=="--resume" ( set "GEMMA_TPU_SUITE_RESUME=1" & shift & goto :parse_args )
if /i "!_arg!"=="--no-resume" ( set "GEMMA_TPU_SUITE_RESUME=0" & shift & goto :parse_args )
if /i "!_arg!"=="--require-tpu-hbm" ( set "GEMMA_TPU_SUITE_REQUIRE_HBM=1" & shift & goto :parse_args )
if /i "!_arg!"=="--no-require-tpu-hbm" ( set "GEMMA_TPU_SUITE_REQUIRE_HBM=0" & shift & goto :parse_args )
if /i "!_arg!"=="--local-exec" ( set "GEMMA_TPU_SUITE_LOCAL_EXEC=1" & shift & goto :parse_args )
if /i "!_arg!"=="--dry-run" ( set "GEMMA_TPU_SUITE_DRY_RUN=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for benchmark_experiments.cmd.
:show_help
echo Usage: benchmark_experiments.cmd [--tfrc-config=^<path^>] [--repo-dir=^<dir^>] [--results-dir=^<dir^>] [--model=^<id^>] [--backends=^<csv^|all^>] [--subsuites=E0,E1,E2,E3,E4] [--command-template=^<tpl^>] [--fresh-vm-per-backend] [--resume] [--local-exec]
exit /b 0

:: ## after_args
:: Dispatches E0-E4 sub-suites locally or across remote Cloud TPU VM workers.
:after_args
if /i "!GEMMA_TPU_SUITE_BACKENDS!"=="all" set "GEMMA_TPU_SUITE_BACKENDS=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native"
if not exist "!GEMMA_TPU_SUITE_RESULTS_DIR!\raw" mkdir "!GEMMA_TPU_SUITE_RESULTS_DIR!\raw"

if "!GEMMA_TPU_SUITE_DRY_RUN!"=="1" (
    call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
    if not errorlevel 1 (
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_require_config "!GEMMA_TPU_SUITE_REPO_DIR!"
        if errorlevel 1 exit /b !errorlevel!
        call "%LIBSCRIPT_ROOT_DIR%\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
        if errorlevel 1 exit /b !errorlevel!
    )
    echo [DRY-RUN] gemma-tpu-suite repo=!GEMMA_TPU_SUITE_REPO_DIR! results=!GEMMA_TPU_SUITE_RESULTS_DIR! model=!GEMMA_TPU_SUITE_MODEL! backends=!GEMMA_TPU_SUITE_BACKENDS! subsuites=!GEMMA_TPU_SUITE_SUBSUITES!
    exit /b 0
)

if "!GEMMA_TPU_SUITE_LOCAL_EXEC!"=="1" goto :run_local_matrix
if "%TPU_NAME%"=="" goto :run_local_matrix
goto :run_remote_matrix

:: ## run_local_matrix
:: Executes E0-E4 locally on the current host or stub environment.
:run_local_matrix
echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E0," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e0_tfrc_provenance.cmd" "!GEMMA_TPU_SUITE_REPO_DIR!" "!GEMMA_TPU_SUITE_RESULTS_DIR!" "!GEMMA_TPU_SUITE_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
)
set "_first_be=1"
set "_be_list=!GEMMA_TPU_SUITE_BACKENDS:,= !"
for %%B in (!_be_list!) do (
    call :run_local_backend_cell "%%B"
    if errorlevel 1 exit /b !errorlevel!
)
echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E4," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e4_custom_matrix_and_synthesis.cmd" "!GEMMA_TPU_SUITE_REPO_DIR!" "!GEMMA_TPU_SUITE_RESULTS_DIR!" "!GEMMA_TPU_SUITE_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
)
exit /b 0

:: ## run_local_backend_cell
:: Runs E1-E3 locally for one backend, optionally cycling TPU_NAME if set alongside --local-exec.
:run_local_backend_cell
set "_loc_bid=%~1"
if "!_first_be!"=="0" if not "%TPU_NAME%"=="" (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_cycle_vm_for_backend "%TPU_NAME%" "!_loc_bid!" "!GEMMA_TPU_SUITE_REPO_DIR!"
    if errorlevel 1 exit /b !errorlevel!
)
set "_first_be=0"
echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E1," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e1_inference_throughput.cmd" "!GEMMA_TPU_SUITE_REPO_DIR!" "!GEMMA_TPU_SUITE_RESULTS_DIR!" "!_loc_bid!"
    if errorlevel 1 exit /b !errorlevel!
)
echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E2," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e2_sql_evaluation.cmd" "!GEMMA_TPU_SUITE_REPO_DIR!" "!GEMMA_TPU_SUITE_RESULTS_DIR!" "!_loc_bid!"
    if errorlevel 1 exit /b !errorlevel!
)
echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E3," >nul 2>&1
if not errorlevel 1 (
    call "!SCRIPT_DIR!\suites\e3_training_finetuning.cmd" "!GEMMA_TPU_SUITE_REPO_DIR!" "!GEMMA_TPU_SUITE_RESULTS_DIR!" "!_loc_bid!"
    if errorlevel 1 exit /b !errorlevel!
)
exit /b 0

:: ## run_remote_matrix
:: Dispatches E0-E4 across remote Cloud TPU VM workers via tpu_matrix.cmd and streams back JSON cells atomically.
:run_remote_matrix
set "_tree_hash=local"
for /f "usebackq delims=" %%H in (`call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" compute-hash "!GEMMA_TPU_SUITE_REPO_DIR!" 2^>nul`) do set "_tree_hash=%%H"

echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E0," >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "jax_native" "./libscript/experiments/gemma-tpu/suites/e0_tfrc_provenance.sh ./workspace ./results '!GEMMA_TPU_SUITE_BACKENDS!'" "!GEMMA_TPU_SUITE_RESULTS_DIR!\logs\E0"
    if errorlevel 1 exit /b !errorlevel!
    call :pull_remote_artifact_atomic "%TPU_NAME%" "raw/e0_provenance.json"
    if errorlevel 1 exit /b !errorlevel!
)

set "_first_be=1"
set "_be_list=!GEMMA_TPU_SUITE_BACKENDS:,= !"
for %%B in (!_be_list!) do (
    call :run_remote_backend_cell "%%B"
    if errorlevel 1 exit /b !errorlevel!
)

echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E4," >nul 2>&1
if not errorlevel 1 (
    set "GEMMA_TPU_SUITE_SKIP_CUSTOM_EXEC=1"
    call "!SCRIPT_DIR!\suites\e4_custom_matrix_and_synthesis.cmd" "!GEMMA_TPU_SUITE_REPO_DIR!" "!GEMMA_TPU_SUITE_RESULTS_DIR!" "!GEMMA_TPU_SUITE_BACKENDS!"
    if errorlevel 1 exit /b !errorlevel!
)
exit /b 0

:: ## run_remote_backend_cell
:: Executes E1-E3 remotely on Cloud TPU VM workers for one backend with Spot --resume skipping and immediate SCP retrieval.
:run_remote_backend_cell
set "_rem_bid=%~1"
if "!_first_be!"=="0" (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_cycle_vm_for_backend "%TPU_NAME%" "!_rem_bid!" "!GEMMA_TPU_SUITE_REPO_DIR!"
    if errorlevel 1 exit /b !errorlevel!
)
set "_first_be=0"

echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E1," >nul 2>&1
if not errorlevel 1 (
    set "_e1f=!GEMMA_TPU_SUITE_RESULTS_DIR!\raw\e1_inference_!_rem_bid!.json"
    set "_skip_e1=0"
    if "!GEMMA_TPU_SUITE_RESUME!"=="1" if exist "!_e1f!" (
        jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!_e1f!" >nul 2>&1
        if not errorlevel 1 set "_skip_e1=1"
    )
    if "!_skip_e1!"=="0" (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "!_rem_bid!" "GEMMA_TPU_SUITE_MODEL='!GEMMA_TPU_SUITE_MODEL!' GEMMA_TPU_SUITE_WARMUP='!GEMMA_TPU_SUITE_WARMUP!' ./libscript/experiments/gemma-tpu/suites/e1_inference_throughput.sh ./workspace ./results '!_rem_bid!'" "!GEMMA_TPU_SUITE_RESULTS_DIR!\logs\E1_!_rem_bid!"
        if errorlevel 1 exit /b !errorlevel!
        call :pull_remote_artifact_atomic "%TPU_NAME%" "raw/e1_inference_!_rem_bid!.json"
        if errorlevel 1 exit /b !errorlevel!
    )
)

echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E2," >nul 2>&1
if not errorlevel 1 (
    set "_e2f=!GEMMA_TPU_SUITE_RESULTS_DIR!\raw\e2_sql_eval_!_rem_bid!.json"
    set "_skip_e2=0"
    if "!GEMMA_TPU_SUITE_RESUME!"=="1" if exist "!_e2f!" (
        jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!_e2f!" >nul 2>&1
        if not errorlevel 1 set "_skip_e2=1"
    )
    if "!_skip_e2!"=="0" (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "!_rem_bid!" "GEMMA_TPU_SUITE_MODEL='!GEMMA_TPU_SUITE_MODEL!' ./libscript/experiments/gemma-tpu/suites/e2_sql_evaluation.sh ./workspace ./results '!_rem_bid!'" "!GEMMA_TPU_SUITE_RESULTS_DIR!\logs\E2_!_rem_bid!"
        if errorlevel 1 exit /b !errorlevel!
        call :pull_remote_artifact_atomic "%TPU_NAME%" "raw/e2_sql_eval_!_rem_bid!.json"
        if errorlevel 1 exit /b !errorlevel!
    )
)

echo ,!GEMMA_TPU_SUITE_SUBSUITES!, | findstr /I /C:",E3," >nul 2>&1
if not errorlevel 1 (
    set "_e3f=!GEMMA_TPU_SUITE_RESULTS_DIR!\raw\e3_training_!_rem_bid!.json"
    set "_skip_e3=0"
    if "!GEMMA_TPU_SUITE_RESUME!"=="1" if exist "!_e3f!" (
        jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!_e3f!" >nul 2>&1
        if not errorlevel 1 set "_skip_e3=1"
    )
    if "!_skip_e3!"=="0" (
        call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_run_lockstep "%TPU_NAME%" "!_rem_bid!" "GEMMA_TPU_SUITE_MODEL='!GEMMA_TPU_SUITE_MODEL!' ./libscript/experiments/gemma-tpu/suites/e3_training_finetuning.sh ./workspace ./results '!_rem_bid!'" "!GEMMA_TPU_SUITE_RESULTS_DIR!\logs\E3_!_rem_bid!"
        if errorlevel 1 exit /b !errorlevel!
        call :pull_remote_artifact_atomic "%TPU_NAME%" "raw/e3_training_!_rem_bid!.json"
        if errorlevel 1 exit /b !errorlevel!
    )
)
exit /b 0

:: ## pull_remote_artifact_atomic
:: Streams a single completed JSON artifact from TPU worker 0 and validates JSON syntax via jq before atomic rename.
:pull_remote_artifact_atomic
set "_pra_tpu=%~1"
set "_pra_rel=%~2"
set "_pra_win=!_pra_rel:/=\!"
set "_pra_local=!GEMMA_TPU_SUITE_RESULTS_DIR!\!_pra_win!"
for %%D in ("!_pra_local!") do if not exist "%%~dpD" mkdir "%%~dpD"
call "%LIBSCRIPT_ROOT_DIR%\infrastructure\providers\gcp-tpu-vm\cli.cmd" scp "!_pra_tpu!" "!_pra_tpu!:~/results/!_pra_rel!" "!_pra_local!.tmp" --worker=0
if errorlevel 1 exit /b !errorlevel!
jq -e . "!_pra_local!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!_pra_local!.tmp" "!_pra_local!" >nul
exit /b 0
