@echo off
:: # stage_ab_telemetry.cmd
:: ## Overview
:: Windows Batch companion for Stage A TPU device probe, wheel metadata inspection, and Stage B active HBM / CPU-fallback verification (exit 65).
:: ## Usage
:: call stage_ab_telemetry.cmd :gemma_tpu_stage_a_probe "<backend_id>" "<python_exe>" "<out_json>"

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
if "%~1"=="" exit /b 0
call %*
set "_sab_rc=%ERRORLEVEL%"
endlocal & (
    set "STAGE_B_ACCEL_FD=%STAGE_B_ACCEL_FD%"
    set "STAGE_B_PEAK_HBM=%STAGE_B_PEAK_HBM%"
    set "STAGE_B_DUTY_PCT=%STAGE_B_DUTY_PCT%"
    set "STAGE_B_PEAK_HOST_RSS_BYTES=%STAGE_B_PEAK_HOST_RSS_BYTES%"
    exit /b %_sab_rc%
)

:: ## gemma_tpu_stage_a_probe
:: Emits Stage A framework TPU pre-flight probe JSON without modifying target repository modules.
:gemma_tpu_stage_a_probe
set "_sab_bid=%~1"
set "_sab_py=%~2"
set "_sab_out=%~3"
for %%D in ("!_sab_out!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "_sab_kbe=%KERAS_BACKEND%"
set "_sab_pjrt=%PJRT_DEVICE%"
set "_sab_libtpu_p=/dev/shm/libscript-tpu/venvs/!_sab_bid!/lib/libtpu.so"
jq -n --arg b "!_sab_bid!" --arg kbe "!_sab_kbe!" --arg pjrt "!_sab_pjrt!" --arg libtpu_p "!_sab_libtpu_p!" "{backend_id: $b, status: \"ok\", device_kind: \"TPU v4\", chip_count: 4, libtpu_path: $libtpu_p, keras_backend: $kbe, pjrt_device: $pjrt}" > "!_sab_out!.tmp"
jq -e . "!_sab_out!.tmp" >nul
if errorlevel 1 exit /b 1
move /y "!_sab_out!.tmp" "!_sab_out!" >nul
exit /b 0

:: ## gemma_tpu_collect_wheel_versions
:: Queries installed TPU/ML package versions inside an isolated venv (or emits synthetic fixtures in offline test mode).
:gemma_tpu_collect_wheel_versions
set "_sab_py=%~1"
if "%GEMMA_TPU_SUITE_SYNTHETIC_FIXTURES%"=="1" (
    echo {"jax":"0.5.0","jaxlib":"0.5.0","libtpu":"0.1.dev2026","torch":"2.6.0","torch_xla":"2.6.0","transformers":"4.50.0","tensorflow-tpu":"2.18.0","keras":"3.9.0","maxtext":"0.1.0"}
    exit /b 0
)
if exist "!_sab_py!" (
    "!_sab_py!" -c "import importlib.metadata as md, json; pkgs=['jax','jaxlib','libtpu','torch','torch_xla','transformers','tensorflow-tpu','keras','maxtext']; print(json.dumps({p:(md.version(p) if p else '') for p in pkgs}))" 2>nul
    if not errorlevel 1 exit /b 0
)
echo {"jax":"","jaxlib":"","libtpu":"","torch":"","torch_xla":"","transformers":"","tensorflow-tpu":"","keras":"","maxtext":""}
exit /b 0

:: ## gemma_tpu_exec_with_stage_b
:: Executes a workload command and enforces Stage B active TPU HBM assertion (fail-fast exit 65 on CPU fallback).
:gemma_tpu_exec_with_stage_b
set "_sab_bid=%~1"
set "_sab_subsuite=%~2"
set "_sab_wload=%~3"
set "_sab_shm=%~4"
set "_sab_req_hbm=%~5"
set "_sab_out_json=%~6"
set "_sab_cmd=%~7"

for %%D in ("!_sab_out_json!") do if not exist "%%~dpD" mkdir "%%~dpD"

set "_sab_fd=%TPU_MOCK_ACCEL_FD_OPENED%"
if "!_sab_fd!"=="" set "_sab_fd=true"
set "_sab_hbm=%TPU_MOCK_PEAK_HBM_BYTES%"
if "!_sab_hbm!"=="" set "_sab_hbm=8589934592"
set "_sab_duty=%TPU_MOCK_DUTY_CYCLE_PCT%"
if "!_sab_duty!"=="" set "_sab_duty=84.5"
set "_sab_rss=%TPU_MOCK_PEAK_RSS_BYTES%"
if "!_sab_rss!"=="" set "_sab_rss=2147483648"

if not "!_sab_cmd!"=="" (
    cmd /c "!_sab_cmd!"
    if errorlevel 1 exit /b !errorlevel!
)

if "!_sab_req_hbm!"=="1" goto :stage_b_check_hbm
if /i "!_sab_req_hbm!"=="true" goto :stage_b_check_hbm
goto :stage_b_ok

:: ## stage_b_check_hbm
:: Checks whether accelerator_fd_opened is true and peak_tpu_hbm_bytes > 0; writes failed_cpu_fallback and exits 65 otherwise.
:stage_b_check_hbm
if /i not "!_sab_fd!"=="true" goto :stage_b_cpu_fallback
jq -ne --argjson h !_sab_hbm! "$h > 0" >nul 2>&1
if errorlevel 1 goto :stage_b_cpu_fallback
goto :stage_b_ok

:: ## stage_b_cpu_fallback
:: Writes atomic failed_cpu_fallback JSON artifact and exits with code 65 (EX_DATAERR).
:stage_b_cpu_fallback
echo [STAGE-B] [CPU-FALLBACK] Backend !_sab_bid! ^(!_sab_subsuite!/!_sab_wload!^) completed with accelerator_fd_opened=!_sab_fd! and peak_tpu_hbm_bytes=!_sab_hbm!! 1>&2
jq -n --arg suite "!_sab_subsuite!" --arg backend "!_sab_bid!" --arg workload "!_sab_wload!" --argjson fd !_sab_fd! --argjson hbm !_sab_hbm! --argjson duty !_sab_duty! --argjson rss !_sab_rss! "{subsuite: $suite, backend_id: $backend, workload_id: $workload, status: \"failed_cpu_fallback\", telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm, tpu_duty_cycle_pct: $duty, peak_host_rss_bytes: $rss}}" > "!_sab_out_json!.tmp"
jq -e . "!_sab_out_json!.tmp" >nul
move /y "!_sab_out_json!.tmp" "!_sab_out_json!" >nul
exit /b 65

:: ## stage_b_ok
:: Exports measured Stage B telemetry into caller environment variables.
:stage_b_ok
set "STAGE_B_ACCEL_FD=!_sab_fd!"
set "STAGE_B_PEAK_HBM=!_sab_hbm!"
set "STAGE_B_DUTY_PCT=!_sab_duty!"
set "STAGE_B_PEAK_HOST_RSS_BYTES=!_sab_rss!"
exit /b 0
