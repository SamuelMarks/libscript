@echo off
:: # test_gemma_tpu_matrix.cmd
:: ## Overview
:: Hermetic Windows Batch integration test suite for the 7-backend Gemma 4 TPU matrix, 2x --resume idempotency, shm watermark eviction, Stage B CPU-fallback exit 65, teardown cleanup, and >9 argument '=' / ',' forwarding in libscript.cmd.
:: ## Usage
:: tests\test_gemma_tpu_matrix.cmd

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
set "_WDIR=!LIBSCRIPT_ROOT_DIR!\tests_tmp\gemma_matrix_win_%RANDOM%"
if not exist "!_WDIR!\bin" mkdir "!_WDIR!\bin"
if not exist "!_WDIR!\repo" mkdir "!_WDIR!\repo"
if not exist "!_WDIR!\shm\cache\hf" mkdir "!_WDIR!\shm\cache\hf"
if not exist "!_WDIR!\shm\venvs\maxtext" mkdir "!_WDIR!\shm\venvs\maxtext"
if not exist "!_WDIR!\shm\venvs\jax-native" mkdir "!_WDIR!\shm\venvs\jax-native"
if not exist "!_WDIR!\out" mkdir "!_WDIR!\out"
echo [project] > "!_WDIR!\repo\pyproject.toml"
echo keep > "!_WDIR!\shm\cache\hf\model.safetensors"

(
    echo @echo off
    echo echo %%* ^| findstr /I /C:"config get-value project" ^>nul ^&^& ^( echo trc-gemma-proj ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"list" ^>nul ^&^& ^( echo [] ^& exit /b 0 ^)
    echo exit /b 0
) > "!_WDIR!\bin\gcloud.cmd"
set "PATH=!_WDIR!\bin;!PATH!"

set "_POL=!_WDIR!\repo\tfrc.policy.json"
jq -n "{schema_version:\"1.0\",gcp_project_id:\"trc-gemma-proj\",strict_zero_cost:true,grants:[{zone:\"us-central2-b\",accelerator_types:[\"v4-8\"],scheduling_tiers:[\"spot\"],max_hosts:1,max_chips:4,max_concurrent_nodes:1,expires_on:\"2026-12-31\"}]}" > "!_POL!"

set "GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES=1"
set "GEMMA_TPU_SUITE_SHM_ROOT=!_WDIR!\shm"
set "GEMMA_TPU_SUITE_LOCAL_EXEC=1"
set "TFRC_MOCK_UTC_DATE=2026-11-14"
set "TPU_MOCK_SHM_FREE_KB=67108864"

:: 1. Pass >10 arguments containing '=' and ',' through libscript.cmd experiment tpu_matrix
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment tpu_matrix "--tfrc-config=!_POL!" "--repo-dir=!_WDIR!\repo" "--output-dir=!_WDIR!\out" "--state-file=!_WDIR!\state.json" "--model=google/gemma-4-E4B" "--backends=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native" "--subsuites=E0,E1,E2,E3,E4" --tfrc-only "--warmup=1" "--trials=2"
if errorlevel 1 goto :fail
if not exist "!_WDIR!\out\gemma_tpu\comparison_summary.json" goto :fail
if not exist "!_WDIR!\out\gemma_tpu\comparison_summary.csv" goto :fail
if not exist "!_WDIR!\out\gemma_tpu\comparison_summary.md" goto :fail
if not exist "!_WDIR!\out\gemma_tpu\generated_metrics.tex" goto :fail
jq -e "(.backends | length) == 7" "!_WDIR!\out\gemma_tpu\comparison_summary.json" >nul || goto :fail

:: 2. 2x --resume idempotency produces identical comparison_summary.json
copy /y "!_WDIR!\out\gemma_tpu\comparison_summary.json" "!_WDIR!\summary_pass1.json" >nul
call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\gemma-tpu-suite\benchmark_experiments.cmd" --local-exec --resume "--tfrc-config=!_POL!" "--repo-dir=!_WDIR!\repo" "--results-dir=!_WDIR!\out\gemma_tpu" "--backends=all" "--subsuites=E0,E1,E2,E3,E4"
if errorlevel 1 goto :fail
fc /b "!_WDIR!\summary_pass1.json" "!_WDIR!\out\gemma_tpu\comparison_summary.json" >nul || goto :fail

:: 3. /dev/shm watermark eviction preserves cache\hf\model.safetensors
set "TPU_MOCK_SHM_FREE_KB=1024"
call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tpu_matrix.cmd" :libscript_tpu_evict_shm_if_needed "jax-native" "!_WDIR!\shm" "32"
if errorlevel 1 goto :fail
if not exist "!_WDIR!\shm\cache\hf\model.safetensors" goto :fail
if exist "!_WDIR!\shm\venvs\maxtext" goto :fail
if not exist "!_WDIR!\shm\venvs\jax-native" goto :fail
set "TPU_MOCK_SHM_FREE_KB=67108864"

:: 4. Stage B fail-fast CPU-fallback detection (peak_tpu_hbm_bytes == 0 -> status == failed_cpu_fallback, exit 65)
set "TPU_MOCK_PEAK_HBM_BYTES=0"
set "TPU_MOCK_ACCEL_FD_OPENED=false"
call "!LIBSCRIPT_ROOT_DIR!\_lib\toolchains\gemma-tpu-suite\benchmark_experiments.cmd" --local-exec --no-resume "--tfrc-config=!_POL!" "--repo-dir=!_WDIR!\repo" "--results-dir=!_WDIR!\out_fb" "--backends=jax_native" "--subsuites=E1" >nul 2>&1
if not "!ERRORLEVEL!"=="65" goto :fail
jq -e ".status == \"failed_cpu_fallback\"" "!_WDIR!\out_fb\raw\e1_inference_jax_native.json" >nul || goto :fail

rmdir /s /q "!_WDIR!" >nul 2>&1
echo [PASS] All Windows 7-backend Gemma 4 TPU matrix and ^>9 arg forwarding tests passed^^!
exit /b 0

:: ## fail
:: Cleans up temporary test workspace and exits with status 1 on failure.
:fail
rmdir /s /q "!_WDIR!" >nul 2>&1
echo [FAIL] Windows 7-backend Gemma 4 TPU matrix test failed^^! 1>&2
exit /b 1
