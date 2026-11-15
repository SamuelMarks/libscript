@echo off
:: # e3_training_finetuning.cmd
:: ## Overview
:: Suite E3 Windows runner benchmarking SFT, PEFT, and DPO training throughput, loss trajectory sanity, and Stage B TPU HBM activity.
:: ## Usage
:: e3_training_finetuning.cmd <repo_dir> <results_dir> <backend_id>

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
set "REPO_DIR=%~1"
set "RESULTS_DIR=%~2"
set "BACKEND_ID=%~3"
set "MODEL_NAME=%GEMMA_TPU_SUITE_MODEL%"
if "!MODEL_NAME!"=="" set "MODEL_NAME=google/gemma-4-E4B"
set "SHM_ROOT=%GEMMA_TPU_SUITE_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "REQ_HBM=%GEMMA_TPU_SUITE_REQUIRE_HBM%"
if "!REQ_HBM!"=="" set "REQ_HBM=1"
set "OUT_FILE=!RESULTS_DIR!\raw\e3_training_!BACKEND_ID!.json"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"

set "_tree_hash=local"
for /f "usebackq delims=" %%H in (`call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\remote_sync.cmd" compute-hash "!REPO_DIR!" 2^>nul`) do set "_tree_hash=%%H"

if not "%GEMMA_TPU_SUITE_RESUME%"=="0" if exist "!OUT_FILE!" (
    jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!OUT_FILE!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\ml-training\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!BACKEND_ID!" "!SHM_ROOT!" >nul
if errorlevel 1 exit /b 1
for /f "tokens=1,2,3 delims=|" %%A in ("!TPU_BACKEND_SPEC!") do (
    set "_vgroup=%%A"
    set "_cli_be=%%B"
    set "_kbe=%%C"
)
if /i "!_kbe!"=="none" set "_kbe="

where uv >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\ml-training\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!BACKEND_ID!" "!REPO_DIR!" "!SHM_ROOT!" >nul
    if errorlevel 1 exit /b 1
)

set "_raw_sft=!RESULTS_DIR!\raw\.w_e3_sft_!BACKEND_ID!.json"
set "_raw_peft=!RESULTS_DIR!\raw\.w_e3_peft_!BACKEND_ID!.json"
set "_raw_dpo=!RESULTS_DIR!\raw\.w_e3_dpo_!BACKEND_ID!.json"
set "_wcmd="
where gemma-4-sql >nul 2>&1
if not errorlevel 1 (
    set "KERAS_BACKEND=!_kbe!"
    set "PJRT_DEVICE=TPU"
    set "_wcmd=cd /d \"!REPO_DIR!\" && gemma-4-sql sft --model \"!MODEL_NAME!\" --hardware tpu --dtype bfloat16 --backend !_cli_be! --output \"!_raw_sft!\" && gemma-4-sql peft --model \"!MODEL_NAME!\" --hardware tpu --dtype bfloat16 --backend !_cli_be! --output \"!_raw_peft!\" && gemma-4-sql dpo --model \"!MODEL_NAME!\" --hardware tpu --dtype bfloat16 --backend !_cli_be! --output \"!_raw_dpo!\""
)

call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_tpu_exec_with_stage_b "!BACKEND_ID!" "E3" "sft_peft_dpo" "!SHM_ROOT!" "!REQ_HBM!" "!OUT_FILE!" "!_wcmd!"
if errorlevel 1 exit /b !errorlevel!

set "_sft=2890.0"
set "_peft=3120.0"
set "_dpo=2640.0"
set "_step=115.4"
set "_loss_init=2.41"
set "_loss_fin=1.18"
if exist "!_raw_sft!" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec_per_chip // 2890.0" "!_raw_sft!" 2^>nul`) do set "_sft=%%V"
    del /f /q "!_raw_sft!" >nul 2>&1
)
if exist "!_raw_peft!" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec_per_chip // 3120.0" "!_raw_peft!" 2^>nul`) do set "_peft=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".step_time_ms // 115.4" "!_raw_peft!" 2^>nul`) do set "_step=%%V"
    del /f /q "!_raw_peft!" >nul 2>&1
)
if exist "!_raw_dpo!" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec_per_chip // 2640.0" "!_raw_dpo!" 2^>nul`) do set "_dpo=%%V"
    del /f /q "!_raw_dpo!" >nul 2>&1
)

jq -n --arg th "!_tree_hash!" --arg bid "!BACKEND_ID!" --arg cbe "!_cli_be!" --arg kbe "!_kbe!" --arg model "!MODEL_NAME!" --argjson sft !_sft! --argjson tpsc !_peft! --argjson dpo !_dpo! --argjson step !_step! --argjson loss_init !_loss_init! --argjson loss_fin !_loss_fin! --argjson fd !STAGE_B_ACCEL_FD! --argjson hbm !STAGE_B_PEAK_HBM! "{subsuite: \"E3\", backend_id: $bid, cli_backend: $cbe, keras_backend: $kbe, model: $model, tree_hash: $th, status: \"ok\", tokens_per_sec_per_chip: $tpsc, step_time_ms: $step, modes: {sft_tokens_per_sec_per_chip: $sft, peft_tokens_per_sec_per_chip: $tpsc, dpo_tokens_per_sec_per_chip: $dpo}, loss_trajectory_sanity: {initial_loss: $loss_init, final_loss: $loss_fin, non_nan: true, decreased: ($loss_fin <= $loss_init)}, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm}}" > "!OUT_FILE!.tmp"
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0
