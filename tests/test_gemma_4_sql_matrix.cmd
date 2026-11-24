@echo off
:: # test_gemma_4_sql_matrix.cmd
:: ## Overview
:: Hermetic Windows Batch integration test suite for `experiments\gemma-4-sql\`, strict gemma-4-sql CLI/JSON contracts, relative-path tree-hash safety, 2x --resume idempotency, --render-latex idempotency, shm eviction, Stage B CPU-fallback exit 65, and >9 arg '=' / ',' forwarding.
:: ## Usage
:: tests\test_gemma_4_sql_matrix.cmd

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
if exist "!LIBSCRIPT_ROOT_DIR!\experiments\gemma-tpu" goto :fail
set "_WDIR=!LIBSCRIPT_ROOT_DIR!\tests_tmp\gemma_4_sql_win_%RANDOM%"
if not exist "!_WDIR!\bin" mkdir "!_WDIR!\bin"
if not exist "!_WDIR!\repo" mkdir "!_WDIR!\repo"
if not exist "!_WDIR!\shm\cache\hf" mkdir "!_WDIR!\shm\cache\hf"
if not exist "!_WDIR!\out" mkdir "!_WDIR!\out"
echo [project] > "!_WDIR!\repo\pyproject.toml"
echo duckdb > "!_WDIR!\repo\requirements-duckdb.txt"
echo keep > "!_WDIR!\shm\cache\hf\model.safetensors"

(
    echo @echo off
    echo echo %%* ^| findstr /I /C:"config get-value project" ^>nul ^&^& ^( echo trc-gemma-proj ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"list" ^>nul ^&^& ^( echo [] ^& exit /b 0 ^)
    echo exit /b 0
) > "!_WDIR!\bin\gcloud.cmd"

(
    echo @echo off
    echo if /i "%%~1"=="venv" ^(
    echo   for %%%%A in ^(%%*^) do set "_vp=%%%%~A"
    echo   if not exist "%%_vp%%\Scripts" mkdir "%%_vp%%\Scripts"
    echo   echo @exit /b 0 ^> "%%_vp%%\Scripts\python.exe"
    echo   copy /y "%~dp0" ^>nul 2^>^&1
    echo ^)
    echo exit /b 0
) > "!_WDIR!\bin\uv.cmd"

(
    echo @echo off
    echo set "_out="
    echo :lp
    echo if "%%~1"=="" goto :emit
    echo if /i "%%~1"=="--output" exit /b 2
    echo if /i "%%~1"=="--output-json" ^( set "_out=%%~2" ^& shift ^& shift ^& goto :lp ^)
    echo shift
    echo goto :lp
    echo :emit
    echo if "%%_out%%"=="" exit /b 2
    echo echo {"status":"completed","tokens_per_sec":165.0,"compile_latency_ms":1200.0,"peak_memory_mb":8192.0,"latency_stats":{"mean_ms":18.6,"p25_ms":17.8,"p50_ms":18.5,"p75_ms":19.2,"p90_ms":20.1,"p99_ms":21.0,"min_ms":17.0,"max_ms":21.5},"mean_query_ms":38.4,"metrics":{"execution_accuracy":0.875,"exact_match":0.75,"valid_sql":1.0},"success":true,"attempts":1,"tokens_per_sec_per_chip":3400.0,"step_time_ms":98.0,"initial_loss":2.5,"final_loss":1.1} ^> "%%_out%%"
    echo exit /b 0
) > "!_WDIR!\bin\gemma-4-sql.cmd"

set "PATH=!_WDIR!\bin;!PATH!"

set "_POL=!_WDIR!\repo\tfrc.policy.json"
jq -n "{schema_version:\"1.0\",gcp_project_id:\"trc-gemma-proj\",strict_zero_cost:true,grants:[{zone:\"us-central2-b\",accelerator_types:[\"v4-8\"],scheduling_tiers:[\"spot\"],max_hosts:1,max_chips:4,max_concurrent_nodes:1,expires_on:\"2026-12-31\"}]}" > "!_POL!"

set "GEMMA_4_SQL_SYNTHETIC_FIXTURES=1"
set "GEMMA_4_SQL_SHM_ROOT=!_WDIR!\shm"
set "GEMMA_4_SQL_LOCAL_EXEC=1"
set "TFRC_MOCK_UTC_DATE=2026-11-14"
set "TPU_MOCK_SHM_FREE_KB=67108864"

:: 1. Validate plugin and run >10 arguments containing '=' and ',' through libscript.cmd experiment tpu_matrix
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment validate gemma-4-sql "--batch-sizes=1,8,32" >nul
if errorlevel 1 goto :fail
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment tpu_matrix "--tfrc-config=!_POL!" "--repo-dir=!_WDIR!\repo" "--output-dir=!_WDIR!\out" "--state-file=!_WDIR!\state.json" "--model=google/gemma-4-E4B" "--backends=hf_transformers,pytorch_native,keras_jax,keras_tensorflow,keras_pytorch,maxtext,jax_native" "--subsuites=E0,E1,E2,E3,E4" --tfrc-only "--warmup=1" "--trials=2"
if errorlevel 1 goto :fail
if exist "!_WDIR!\repo\results" goto :fail
if not exist "!_WDIR!\out\gemma-4-sql\comparison_summary.json" goto :fail
if not exist "!_WDIR!\out\gemma-4-sql\comparison_summary.csv" goto :fail
if not exist "!_WDIR!\out\gemma-4-sql\comparison_summary.md" goto :fail
if not exist "!_WDIR!\out\gemma-4-sql\generated_metrics.tex" goto :fail
jq -e "(.comparison_families | length) == 5 and (.backends | length) == 7" "!_WDIR!\out\gemma-4-sql\comparison_summary.json" >nul || goto :fail

:: 2. 2x --resume idempotency + --render-latex idempotency
copy /y "!_WDIR!\out\gemma-4-sql\comparison_summary.json" "!_WDIR!\summary_pass1.json" >nul
call "!LIBSCRIPT_ROOT_DIR!\experiments\gemma-4-sql\benchmark_experiments.cmd" --local-exec --resume "--tfrc-config=!_POL!" "--repo-dir=!_WDIR!\repo" "--results-dir=!_WDIR!\out\gemma-4-sql" "--backends=all" "--subsuites=E0,E1,E2,E3,E4"
if errorlevel 1 goto :fail
fc /b "!_WDIR!\summary_pass1.json" "!_WDIR!\out\gemma-4-sql\comparison_summary.json" >nul || goto :fail

call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment render-latex gemma-4-sql "--repo-dir=!_WDIR!\repo" "--results-dir=!_WDIR!\out\gemma-4-sql" "--paper-dir=!_WDIR!\paper"
if errorlevel 1 goto :fail
if not exist "!_WDIR!\paper\generated_metrics.tex" goto :fail

:: 3. /dev/shm watermark eviction preserves cache\hf\model.safetensors
set "TPU_MOCK_SHM_FREE_KB=1024"
call "!LIBSCRIPT_ROOT_DIR!\workloads\ai\_common\tpu_matrix.cmd" :libscript_tpu_evict_shm_if_needed "jax-native" "!_WDIR!\shm" "32"
if errorlevel 1 goto :fail
if not exist "!_WDIR!\shm\cache\hf\model.safetensors" goto :fail
if exist "!_WDIR!\shm\venvs\maxtext" goto :fail
if not exist "!_WDIR!\shm\venvs\jax-native" goto :fail
set "TPU_MOCK_SHM_FREE_KB=67108864"

:: 4. Stage B fail-fast CPU-fallback detection (peak_tpu_hbm_bytes == 0 -> status == failed_cpu_fallback, exit 65)
set "TPU_MOCK_PEAK_HBM_BYTES=0"
set "TPU_MOCK_ACCEL_FD_OPENED=false"
call "!LIBSCRIPT_ROOT_DIR!\experiments\gemma-4-sql\benchmark_experiments.cmd" --local-exec --no-resume "--tfrc-config=!_POL!" "--repo-dir=!_WDIR!\repo" "--results-dir=!_WDIR!\out_fb" "--backends=jax_native" "--subsuites=E1" >nul 2>&1
if not "!ERRORLEVEL!"=="65" goto :fail
jq -e ".status == \"failed_cpu_fallback\"" "!_WDIR!\out_fb\raw\e1_inference_jax_native.json" >nul || goto :fail

rmdir /s /q "!_WDIR!" >nul 2>&1
echo [PASS] All Windows gemma-4-sql 5-family / 7-backend TPU matrix tests passed^^!
exit /b 0

:: ## fail
:: Cleans up temporary test workspace and exits with status 1 on failure.
:fail
rmdir /s /q "!_WDIR!" >nul 2>&1
echo [FAIL] Windows gemma-4-sql 7-backend TPU matrix test failed^^! 1>&2
exit /b 1
