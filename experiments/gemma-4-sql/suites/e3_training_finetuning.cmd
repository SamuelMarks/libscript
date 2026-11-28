@echo off
:: # e3_training_finetuning.cmd
:: ## Overview
:: Suite E3 Windows runner benchmarking SFT, LoRA (PEFT), and DPO training throughput, step time, loss trajectory sanity, and Stage B TPU HBM activity.
:: ## Usage
:: e3_training_finetuning.cmd <repo_dir> <results_dir> <backend_id>

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Canonicalizes paths and executes E3 SFT/PEFT/DPO training benchmarks for BACKEND_ID.
:root_found
set "_e3_repo_arg=%~1"
set "_e3_res_arg=%~2"
set "BACKEND_ID=%~3"
set "MODEL_NAME=%GEMMA_4_SQL_MODEL%"
if "!MODEL_NAME!"=="" set "MODEL_NAME=google/gemma-4-E4B"
set "DATASET_ID=%GEMMA_4_SQL_DATASET%"
if "!DATASET_ID!"=="" set "DATASET_ID=gemma-4-sql-bench"
set "SHM_ROOT=%GEMMA_4_SQL_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "LIBTPU_PROVIDER=%GEMMA_4_SQL_LIBTPU_PROVIDER%"
if "!LIBTPU_PROVIDER!"=="" set "LIBTPU_PROVIDER=og"

for %%I in ("!_e3_repo_arg!") do set "REPO_DIR=%%~fI"
if not exist "!_e3_res_arg!\raw" mkdir "!_e3_res_arg!\raw"
for %%I in ("!_e3_res_arg!") do set "RESULTS_DIR=%%~fI"
set "OUT_FILE=!RESULTS_DIR!\raw\e3_training_!BACKEND_ID!.json"

call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" :libscript_compute_tree_hash "!REPO_DIR!" >nul
set "_tree_hash=!LIBSCRIPT_TREE_HASH!"

if not "%GEMMA_4_SQL_RESUME%"=="0" if exist "!OUT_FILE!" (
    jq -e --arg th "!_tree_hash!" --arg prov "!LIBTPU_PROVIDER!" --arg prov "!LIBTPU_PROVIDER!" ".status == \"ok\" and .tree_hash == $th and (.libtpu_provider // \"og\") == $prov" "!OUT_FILE!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!BACKEND_ID!" "!REPO_DIR!" "!SHM_ROOT!" "!LIBTPU_PROVIDER!" >nul
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_provider_env "!TPU_BACKEND_VENV_DIR!" "!LIBTPU_PROVIDER!" >nul
if errorlevel 1 exit /b 1
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!BACKEND_ID!" "!SHM_ROOT!" >nul
call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_family_label "!BACKEND_ID!" >nul
for /f "tokens=2,3 delims=|" %%C in ("!TPU_BACKEND_SPEC!") do (
    set "_cli_be=%%C"
    set "_kbe=%%D"
)
if /i "!_kbe!"=="none" set "_kbe="
set "KERAS_BACKEND=!_kbe!"
set "PATH=!TPU_BACKEND_VENV_DIR!\Scripts;!TPU_BACKEND_VENV_DIR!\bin;!PATH!"

set "_fix_dir=!RESULTS_DIR!\fixtures"
if not exist "!_fix_dir!" mkdir "!_fix_dir!"
if not exist "!_fix_dir!\train_sft_seed42.jsonl" (
    > "!_fix_dir!\train_sft_seed42.jsonl" echo {"prompt":"List department names with average salary above 100000","completion":"SELECT d.name FROM departments d JOIN employees e ON d.id = e.dept_id GROUP BY d.id, d.name HAVING AVG(e.salary) > 100000;"}
)
if not exist "!_fix_dir!\train_dpo_seed42.jsonl" (
    > "!_fix_dir!\train_dpo_seed42.jsonl" echo {"prompt":"Count total employees in Engineering","chosen":"SELECT COUNT(*) FROM employees e JOIN departments d ON e.dept_id = d.id WHERE d.name = 'Engineering';","rejected":"SELECT * FROM employees;"}
)
set "_sft_ds=!DATASET_ID!"
set "_dpo_ds=!DATASET_ID!"
if /i "!DATASET_ID!"=="gemma-4-sql-bench" (
    set "_sft_ds=!_fix_dir!\train_sft_seed42.jsonl"
    set "_dpo_ds=!_fix_dir!\train_dpo_seed42.jsonl"
)

set "_strict_flag="
if not "%GEMMA_4_SQL_REQUIRE_HBM%"=="0" set "_strict_flag=--strict-hardware"

set "_raw_sft=!RESULTS_DIR!\raw\.w_e3_sft_!BACKEND_ID!.json"
set "_raw_peft=!RESULTS_DIR!\raw\.w_e3_peft_!BACKEND_ID!.json"
set "_raw_dpo=!RESULTS_DIR!\raw\.w_e3_dpo_!BACKEND_ID!.json"
del /f /q "!_raw_sft!" "!_raw_peft!" "!_raw_dpo!" >nul 2>&1

set "_wcmd=cd /d \"!REPO_DIR!\" && gemma-4-sql sft --model \"!MODEL_NAME!\" --dataset \"!_sft_ds!\" --hardware tpu !_strict_flag! --dtype bfloat16 --backend \"!_cli_be!\" --output-json \"!_raw_sft!\" && gemma-4-sql peft --model \"!MODEL_NAME!\" --dataset \"!_sft_ds!\" --hardware tpu !_strict_flag! --dtype bfloat16 --backend \"!_cli_be!\" --output-json \"!_raw_peft!\" && gemma-4-sql dpo --model \"!MODEL_NAME!\" --dataset \"!_dpo_ds!\" --hardware tpu !_strict_flag! --dtype bfloat16 --backend \"!_cli_be!\" --output-json \"!_raw_dpo!\""

call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_exec_with_stage_b "!BACKEND_ID!" "!_wcmd!" "!OUT_FILE!" "%GEMMA_4_SQL_REQUIRE_HBM%" "!_raw_peft!"
if errorlevel 1 exit /b !errorlevel!

if not exist "!_raw_sft!" exit /b 1
if not exist "!_raw_peft!" exit /b 1
if not exist "!_raw_dpo!" exit /b 1

set "_sft_tpsc="
set "_peft_tpsc="
set "_dpo_tpsc="
set "_step_ms="
set "_loss_init="
set "_loss_fin="
for /f "usebackq delims=" %%V in (`jq -er ".tokens_per_sec_per_chip // .tokens_per_sec" "!_raw_sft!" 2^>nul`) do set "_sft_tpsc=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".tokens_per_sec_per_chip // .tokens_per_sec" "!_raw_peft!" 2^>nul`) do set "_peft_tpsc=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".step_time_ms // .latency_ms" "!_raw_peft!" 2^>nul`) do set "_step_ms=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".initial_loss" "!_raw_peft!" 2^>nul`) do set "_loss_init=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".final_loss" "!_raw_peft!" 2^>nul`) do set "_loss_fin=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".tokens_per_sec_per_chip // .tokens_per_sec" "!_raw_dpo!" 2^>nul`) do set "_dpo_tpsc=%%V"
del /f /q "!_raw_sft!" "!_raw_peft!" "!_raw_dpo!" >nul 2>&1

if "!_sft_tpsc!"=="" exit /b 1
if "!_peft_tpsc!"=="" exit /b 1
if "!_dpo_tpsc!"=="" exit /b 1
if "!_step_ms!"=="" exit /b 1
if "!_loss_init!"=="" exit /b 1
if "!_loss_fin!"=="" exit /b 1

jq -n --arg b "!BACKEND_ID!" --arg fam "!TPU_BACKEND_FAMILY!" --arg m "!MODEL_NAME!" --arg th "!_tree_hash!" --argjson sft_tps !_sft_tpsc! --argjson peft_tps !_peft_tpsc! --argjson dpo_tps !_dpo_tpsc! --argjson step_ms !_step_ms! --argjson loss_init !_loss_init! --argjson loss_fin !_loss_fin! --argjson fd !STAGE_B_ACCEL_FD! --argjson hbm !STAGE_B_PEAK_HBM! "{suite: \"E3\", experiment_id: \"gemma-4-sql\", backend_id: $b, libtpu_provider: $prov, comparison_family: $fam, model: $m, status: \"ok\", tree_hash: $th, sft_tokens_per_sec_per_chip: $sft_tps, peft_tokens_per_sec_per_chip: $peft_tps, dpo_tokens_per_sec_per_chip: $dpo_tps, step_time_ms: $step_ms, loss_trajectory: {initial_loss: $loss_init, final_loss: $loss_fin, loss_decreased: ($loss_fin < $loss_init)}, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm}}" > "!OUT_FILE!.tmp"
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0
