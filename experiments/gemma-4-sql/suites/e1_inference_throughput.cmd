@echo off
:: # e1_inference_throughput.cmd
:: ## Overview
:: Suite E1 Windows runner evaluating Gemma 4 prefill and decode throughput across integer batch sizes, latency quantiles, host RSS, and Stage B TPU HBM activity.
:: ## Usage
:: e1_inference_throughput.cmd <repo_dir> <results_dir> <backend_id>

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
:: Canonicalizes paths and executes E1 prefill/decode batch sweep for BACKEND_ID.
:root_found
set "_e1_repo_arg=%~1"
set "_e1_res_arg=%~2"
set "BACKEND_ID=%~3"
set "MODEL_NAME=%GEMMA_4_SQL_MODEL%"
if "!MODEL_NAME!"=="" set "MODEL_NAME=google/gemma-4-E4B"
set "BATCH_SIZES=%GEMMA_4_SQL_BATCH_SIZES%"
if "!BATCH_SIZES!"=="" set "BATCH_SIZES=1,8,32"
set "WARMUP_STEPS=%GEMMA_4_SQL_WARMUP%"
if "!WARMUP_STEPS!"=="" set "WARMUP_STEPS=2"
set "TRIAL_RUNS=%GEMMA_4_SQL_TRIALS%"
if "!TRIAL_RUNS!"=="" set "TRIAL_RUNS=5"
set "SHM_ROOT=%GEMMA_4_SQL_SHM_ROOT%"
if "!SHM_ROOT!"=="" set "SHM_ROOT=%TEMP%\libscript-tpu"

for %%I in ("!_e1_repo_arg!") do set "REPO_DIR=%%~fI"
if not exist "!_e1_res_arg!\raw" mkdir "!_e1_res_arg!\raw"
for %%I in ("!_e1_res_arg!") do set "RESULTS_DIR=%%~fI"
set "OUT_FILE=!RESULTS_DIR!\raw\e1_inference_!BACKEND_ID!.json"

call "%LIBSCRIPT_ROOT_DIR%\engine\common\remote_sync.cmd" :libscript_compute_tree_hash "!REPO_DIR!" >nul
set "_tree_hash=!LIBSCRIPT_TREE_HASH!"

if not "%GEMMA_4_SQL_RESUME%"=="0" if exist "!OUT_FILE!" (
    jq -e --arg th "!_tree_hash!" ".status == \"ok\" and .tree_hash == $th" "!OUT_FILE!" >nul 2>&1
    if not errorlevel 1 exit /b 0
)

call "%LIBSCRIPT_ROOT_DIR%\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_prepare_backend_venv "!BACKEND_ID!" "!REPO_DIR!" "!SHM_ROOT!" >nul
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

set "_strict_flag="
if not "%GEMMA_4_SQL_REQUIRE_HBM%"=="0" set "_strict_flag=--strict-hardware"

set "_prof_f=%TEMP%\e1_prof_%RANDOM%.json"
> "!_prof_f!" echo []
set "_best_pre=0"
set "_best_dec=0"
set "_cold_ms=0"
set "_p25_ms=0"
set "_p50_ms=0"
set "_p75_ms=0"
set "_p90_ms=0"
set "_p99_ms=0"
set "_any_fd=false"
set "_max_hbm=0"
set "_max_duty=0.0"
set "_max_rss=0"

set "_bs_list=!BATCH_SIZES:,= !"
for %%S in (!_bs_list!) do (
    call :run_single_bs "%%S"
    if errorlevel 1 (
        set "_bs_rc=!errorlevel!"
        del /f /q "!_prof_f!" >nul 2>&1
        exit /b !_bs_rc!
    )
)

jq -n --slurpfile profiles "!_prof_f!" --arg b "!BACKEND_ID!" --arg fam "!TPU_BACKEND_FAMILY!" --arg m "!MODEL_NAME!" --arg th "!_tree_hash!" --argjson pre !_best_pre! --argjson dec !_best_dec! --argjson cold !_cold_ms! --argjson p25 !_p25_ms! --argjson p50 !_p50_ms! --argjson p75 !_p75_ms! --argjson p90 !_p90_ms! --argjson p99 !_p99_ms! --argjson fd !_any_fd! --argjson hbm !_max_hbm! --argjson duty !_max_duty! --argjson rss !_max_rss! "{suite: \"E1\", experiment_id: \"gemma-4-sql\", backend_id: $b, comparison_family: $fam, model: $m, status: \"ok\", tree_hash: $th, prefill_tokens_per_sec: $pre, decode_tokens_per_sec: $dec, cold_compile_ms: $cold, latency_ms: {p25: $p25, p50: $p50, p75: $p75, p90: $p90, p99: $p99, iqr: (($p75 - $p25) * 1000 | round / 1000)}, batch_profiles: $profiles[0], telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm, tpu_duty_cycle_pct: $duty, peak_host_rss_bytes: $rss}}" > "!OUT_FILE!.tmp"
del /f /q "!_prof_f!" >nul 2>&1
jq -e . "!OUT_FILE!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!OUT_FILE!.tmp" "!OUT_FILE!" >nul
exit /b 0

:: ## run_single_bs
:: Runs prefill and decode benchmarks for a single integer batch size with Stage B verification and strict jq validation.
:run_single_bs
set "_bs=%~1"
set "_raw_pre=!RESULTS_DIR!\raw\.w_e1_pre_bs!_bs!_!BACKEND_ID!.json"
set "_raw_dec=!RESULTS_DIR!\raw\.w_e1_dec_bs!_bs!_!BACKEND_ID!.json"
del /f /q "!_raw_pre!" "!_raw_dec!" >nul 2>&1

set "_wcmd=cd /d \"!REPO_DIR!\" && gemma-4-sql benchmark --model \"!MODEL_NAME!\" --hardware tpu !_strict_flag! --dtype bfloat16 --mode prefill --batch-size !_bs! --warmup-steps !WARMUP_STEPS! --num-runs !TRIAL_RUNS! --backend \"!_cli_be!\" --output-json \"!_raw_pre!\" && gemma-4-sql benchmark --model \"!MODEL_NAME!\" --hardware tpu !_strict_flag! --dtype bfloat16 --mode decode --batch-size !_bs! --warmup-steps !WARMUP_STEPS! --num-runs !TRIAL_RUNS! --backend \"!_cli_be!\" --output-json \"!_raw_dec!\""

call "!SCRIPT_DIR!\stage_ab_telemetry.cmd" :gemma_4_sql_exec_with_stage_b "!BACKEND_ID!" "!_wcmd!" "!OUT_FILE!" "%GEMMA_4_SQL_REQUIRE_HBM%" "!_raw_dec!"
if errorlevel 1 exit /b !errorlevel!

if not exist "!_raw_pre!" exit /b 1
if not exist "!_raw_dec!" exit /b 1

set "_bs_pre="
set "_bs_dec="
set "_bs_cold="
set "_bs_p25="
set "_bs_p50="
set "_bs_p75="
set "_bs_p90="
set "_bs_p99="
for /f "usebackq delims=" %%V in (`jq -er ".tokens_per_sec" "!_raw_pre!" 2^>nul`) do set "_bs_pre=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".tokens_per_sec" "!_raw_dec!" 2^>nul`) do set "_bs_dec=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".compile_latency_ms" "!_raw_pre!" 2^>nul`) do set "_bs_cold=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".latency_stats.p25_ms // .latency_stats.min_ms" "!_raw_dec!" 2^>nul`) do set "_bs_p25=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".latency_stats.p50_ms" "!_raw_dec!" 2^>nul`) do set "_bs_p50=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".latency_stats.p75_ms // .latency_stats.p90_ms" "!_raw_dec!" 2^>nul`) do set "_bs_p75=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".latency_stats.p90_ms" "!_raw_dec!" 2^>nul`) do set "_bs_p90=%%V"
for /f "usebackq delims=" %%V in (`jq -er ".latency_stats.p99_ms" "!_raw_dec!" 2^>nul`) do set "_bs_p99=%%V"
del /f /q "!_raw_pre!" "!_raw_dec!" >nul 2>&1

if "!_bs_pre!"=="" exit /b 1
if "!_bs_dec!"=="" exit /b 1
if "!_bs_cold!"=="" exit /b 1
if "!_bs_p50!"=="" exit /b 1
if "!_bs_p99!"=="" exit /b 1

if /i "!STAGE_B_ACCEL_FD!"=="true" set "_any_fd=true"
set "_max_hbm=!STAGE_B_PEAK_HBM!"
set "_max_duty=!STAGE_B_DUTY_PCT!"
set "_max_rss=!STAGE_B_PEAK_HOST_RSS_BYTES!"

if "!_cold_ms!"=="0" set "_cold_ms=!_bs_cold!"
if "!_bs!"=="1" (
    set "_p25_ms=!_bs_p25!" & set "_p50_ms=!_bs_p50!" & set "_p75_ms=!_bs_p75!" & set "_p90_ms=!_bs_p90!" & set "_p99_ms=!_bs_p99!"
)
if "!_p50_ms!"=="0" (
    set "_p25_ms=!_bs_p25!" & set "_p50_ms=!_bs_p50!" & set "_p75_ms=!_bs_p75!" & set "_p90_ms=!_bs_p90!" & set "_p99_ms=!_bs_p99!"
)
for /f "usebackq delims=" %%M in (`jq -rn --argjson a !_best_pre! --argjson b !_bs_pre! "if $b > $a then $b else $a end"`) do set "_best_pre=%%M"
for /f "usebackq delims=" %%M in (`jq -rn --argjson a !_best_dec! --argjson b !_bs_dec! "if $b > $a then $b else $a end"`) do set "_best_dec=%%M"

jq --argjson bs !_bs! --argjson pre !_bs_pre! --argjson dec !_bs_dec! --argjson cold !_bs_cold! --argjson p50 !_bs_p50! --argjson p99 !_bs_p99! ". + [{batch_size: $bs, prefill_tokens_per_sec: $pre, decode_tokens_per_sec: $dec, compile_latency_ms: $cold, latency_p50_ms: $p50, latency_p99_ms: $p99}]" "!_prof_f!" > "!_prof_f!.tmp"
move /y "!_prof_f!.tmp" "!_prof_f!" >nul
exit /b 0
