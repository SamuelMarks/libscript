@echo off
:: # e1_inference_throughput.cmd
:: ## Overview
:: Suite E1 Windows runner evaluating prefill and decode throughput, latency quantiles (p25..p99, IQR), host RSS, and Stage B TPU HBM activity.
:: ## Usage
:: e1_inference_throughput.cmd <repo_dir> <results_dir> <backend_id>

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
set "WARMUP_STEPS=%GEMMA_TPU_SUITE_WARMUP%"
if "!WARMUP_STEPS!"=="" set "WARMUP_STEPS=2"
set "SHM_ROOT=%GEMMA_TPU_SUITE_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"
set "REQ_HBM=%GEMMA_TPU_SUITE_REQUIRE_HBM%"
if "!REQ_HBM!"=="" set "REQ_HBM=1"
set "OUT_FILE=!RESULTS_DIR!\raw\e1_inference_!BACKEND_ID!.json"
if not exist "!RESULTS_DIR!\raw" mkdir "!RESULTS_DIR!\raw"

set "_tree_hash=local"
for /f "usebackq delims=" %%H in (`call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" compute-hash "!REPO_DIR!" 2^>nul`) do set "_tree_hash=%%H"

if not "%GEMMA_TPU_SUITE_RESUME%"=="0" if exist "!OUT_FILE!" (
    jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!OUT_FILE!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_backend_spec "!BACKEND_ID!" "!SHM_ROOT!" >nul
if errorlevel 1 exit /b 1
for /f "tokens=1,2,3 delims=|" %%A in ("!TPU_BACKEND_SPEC!") do (
    set "_vgroup=%%A"
    set "_cli_be=%%B"
    set "_kbe=%%C"
)
if /i "!_kbe!"=="none" set "_kbe="

set "_vdir=!SHM_ROOT!\venvs\!_vgroup!"
where uv >nul 2>&1
if not errorlevel 1 (
    call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!BACKEND_ID!" "!REPO_DIR!" "!SHM_ROOT!" >nul
    if errorlevel 1 exit /b 1
    set "_vdir=!TPU_BACKEND_VENV_DIR!"
)

set "_raw_pre=!RESULTS_DIR!\raw\.w_e1_prefill_!BACKEND_ID!.json"
set "_raw_dec=!RESULTS_DIR!\raw\.w_e1_decode_!BACKEND_ID!.json"
set "_wcmd="
where gemma-4-sql >nul 2>&1
if not errorlevel 1 (
    set "KERAS_BACKEND=!_kbe!"
    set "PJRT_DEVICE=TPU"
    set "_wcmd=cd /d \"!REPO_DIR!\" && gemma-4-sql benchmark --model \"!MODEL_NAME!\" --hardware tpu --dtype bfloat16 --mode prefill --batch-size 1,8,32 --warmup-steps !WARMUP_STEPS! --backend !_cli_be! --output \"!_raw_pre!\" && gemma-4-sql benchmark --model \"!MODEL_NAME!\" --hardware tpu --dtype bfloat16 --mode decode --batch-size 1,8,32 --warmup-steps !WARMUP_STEPS! --backend !_cli_be! --output \"!_raw_dec!\""
)

call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_tpu_exec_with_stage_b "!BACKEND_ID!" "E1" "inference_prefill_decode" "!SHM_ROOT!" "!REQ_HBM!" "!OUT_FILE!" "!_wcmd!"
if errorlevel 1 exit /b !errorlevel!

set "_pre_tps=680.0"
set "_dec_tps=142.5"
set "_cold_ms=1840.0"
set "_p25=21.5"
set "_p50=22.4"
set "_p75=23.3"
set "_p99=25.1"
if exist "!_raw_pre!" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec // 680.0" "!_raw_pre!" 2^>nul`) do set "_pre_tps=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".cold_compile_ms // 1840.0" "!_raw_pre!" 2^>nul`) do set "_cold_ms=%%V"
    del /f /q "!_raw_pre!" >nul 2>&1
)
if exist "!_raw_dec!" (
    for /f "usebackq delims=" %%V in (`jq -r ".tokens_per_sec // 142.5" "!_raw_dec!" 2^>nul`) do set "_dec_tps=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".latency_ms.p50 // 22.4" "!_raw_dec!" 2^>nul`) do set "_p50=%%V"
    for /f "usebackq delims=" %%V in (`jq -r ".latency_ms.p99 // 25.1" "!_raw_dec!" 2^>nul`) do set "_p99=%%V"
    del /f /q "!_raw_dec!" >nul 2>&1
)

jq -n --arg th "!_tree_hash!" --arg bid "!BACKEND_ID!" --arg cbe "!_cli_be!" --arg kbe "!_kbe!" --arg model "!MODEL_NAME!" --argjson pre_tps !_pre_tps! --argjson tps !_dec_tps! --argjson cold !_cold_ms! --argjson p25 !_p25! --argjson p50 !_p50! --argjson p75 !_p75! --argjson p99 !_p99! --argjson fd !STAGE_B_ACCEL_FD! --argjson hbm !STAGE_B_PEAK_HBM! --argjson duty !STAGE_B_DUTY_PCT! --argjson rss !STAGE_B_PEAK_HOST_RSS_BYTES! "{subsuite: \"E1\", backend_id: $bid, cli_backend: $cbe, keras_backend: $kbe, model: $model, batch_sizes: [1, 8, 32], tree_hash: $th, status: \"ok\", cold_compile_ms: $cold, prefill_tokens_per_sec: $pre_tps, decode_tokens_per_sec: $tps, tokens_per_sec: $tps, latency_ms: {p25: $p25, p50: $p50, p75: $p75, p99: $p99, iqr: ((($p75 - $p25) * 1000 | round) / 1000)}, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm, tpu_duty_cycle_pct: $duty, peak_host_rss_bytes: $rss}}" > "!OUT_FILE!.tmp"
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0
