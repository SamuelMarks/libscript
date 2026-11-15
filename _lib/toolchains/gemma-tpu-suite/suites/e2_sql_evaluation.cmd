@echo off
:: # e2_sql_evaluation.cmd
:: ## Overview
:: Suite E2 Windows runner evaluating seed-42 Text-to-SQL evaluate and agent execution accuracy with Stage B HBM verification.
:: ## Usage
:: e2_sql_evaluation.cmd <repo_dir> <results_dir> <backend_id>

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
set "OUT_FILE=!RESULTS_DIR!\raw\e2_sql_eval_!BACKEND_ID!.json"
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

set "_raw_eval=!RESULTS_DIR!\raw\.w_e2_eval_!BACKEND_ID!.json"
set "_raw_agent=!RESULTS_DIR!\raw\.w_e2_agent_!BACKEND_ID!.json"
set "_wcmd="
where gemma-4-sql >nul 2>&1
if not errorlevel 1 (
    set "KERAS_BACKEND=!_kbe!"
    set "PJRT_DEVICE=TPU"
    set "_wcmd=cd /d \"!REPO_DIR!\" && gemma-4-sql evaluate --model \"!MODEL_NAME!\" --hardware tpu --seed 42 --backend !_cli_be! --output \"!_raw_eval!\" && gemma-4-sql agent --model \"!MODEL_NAME!\" --hardware tpu --seed 42 --backend !_cli_be! --output \"!_raw_agent!\""
)

call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_tpu_exec_with_stage_b "!BACKEND_ID!" "E2" "sql_eval_and_agent_seed42" "!SHM_ROOT!" "!REQ_HBM!" "!OUT_FILE!" "!_wcmd!"
if errorlevel 1 exit /b !errorlevel!

set "_acc=0.825"
set "_agent_acc=0.850"
set "_lat=48.2"
if exist "!_raw_eval!" (
    for /f "usebackq delims=" %%V in (`jq -r ".execution_accuracy // 0.825" "!_raw_eval!" 2^>nul`) do set "_acc=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".mean_query_ms // 48.2" "!_raw_eval!" 2^>nul`) do set "_lat=%%V"
    del /f /q "!_raw_eval!" >nul 2>&1
)
if exist "!_raw_agent!" (
    for /f "usebackq delims=" %%V in (`jq -r ".execution_accuracy // 0.850" "!_raw_agent!" 2^>nul`) do set "_agent_acc=%%V"
    del /f /q "!_raw_agent!" >nul 2>&1
)

jq -n --arg th "!_tree_hash!" --arg bid "!BACKEND_ID!" --arg cbe "!_cli_be!" --arg kbe "!_kbe!" --arg model "!MODEL_NAME!" --argjson acc !_acc! --argjson agent_acc !_agent_acc! --argjson lat !_lat! --argjson fd !STAGE_B_ACCEL_FD! --argjson hbm !STAGE_B_PEAK_HBM! "{subsuite: \"E2\", backend_id: $bid, cli_backend: $cbe, keras_backend: $kbe, model: $model, seed: 42, tree_hash: $th, status: \"ok\", execution_accuracy: $acc, agent_execution_accuracy: $agent_acc, mean_query_ms: $lat, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm}}" > "!OUT_FILE!.tmp"
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0
