@echo off
:: # stage_ab_telemetry.cmd
:: ## Overview
:: Windows Batch companion for Stage A TPU device probe (with `libtpu_provider` + mapped `libtpu.so` SHA-256 metadata), wheel inspection, and Stage B active HBM / CPU-fallback verification (exit 65).
:: ## Usage
:: call stage_ab_telemetry.cmd :gemma_4_sql_stage_a_probe <backend_id> <python_exe>

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
:: Dispatches requested Stage A / Stage B subroutine and exports STAGE_B_* state.
:root_found
set "_sab_sub=%~1"
if "!_sab_sub!"=="" exit /b 0
shift
call !_sab_sub! "%~1" "%~2" "%~3" "%~4" "%~5"
set "_sab_rc=!errorlevel!"
endlocal & (
    set "STAGE_B_ACCEL_FD=%STAGE_B_ACCEL_FD%"
    set "STAGE_B_PEAK_HBM=%STAGE_B_PEAK_HBM%"
    set "STAGE_B_DUTY_PCT=%STAGE_B_DUTY_PCT%"
    set "STAGE_B_PEAK_HOST_RSS_BYTES=%STAGE_B_PEAK_HOST_RSS_BYTES%"
    exit /b %_sab_rc%
)
:: wincheck disable=CMD3005

:: ## gemma_4_sql_stage_a_probe
:: Runs real Python TPU device discovery locally or synthetic fixture JSON when GEMMA_4_SQL_SYNTHETIC_FIXTURES=1.
:gemma_4_sql_stage_a_probe
set "_sab_bid=%~1"
set "_sab_py=%~2"
set "_sab_prov=%GEMMA_4_SQL_LIBTPU_PROVIDER%"
if "!_sab_prov!"=="" set "_sab_prov=%LIBTPU_EXPECTED_PROVIDER%"
if "!_sab_prov!"=="" set "_sab_prov=og"
set "_sab_kbe=%KERAS_BACKEND%"
set "_sab_pjrt=%PJRT_DEVICE%"
if "%GEMMA_4_SQL_SYNTHETIC_FIXTURES%"=="1" (
    set "_sab_libtpu_p=/dev/shm/libscript-tpu/venvs/!_sab_bid!-!_sab_prov!/lib/libtpu.so"
    set "_sab_sha=synthetic_!_sab_prov!_libtpu_sha256"
    if not "%LIBTPU_EXPECTED_SHA256%"=="" set "_sab_sha=%LIBTPU_EXPECTED_SHA256%"
    jq -n --arg b "!_sab_bid!" --arg prov "!_sab_prov!" --arg kbe "!_sab_kbe!" --arg pjrt "!_sab_pjrt!" --arg libtpu_p "!_sab_libtpu_p!" --arg sha "!_sab_sha!" "{backend_id: $b, libtpu_provider: $prov, stage_a_status: \"ok\", device_kind: \"TPU v4\", chip_count: 4, keras_backend_active: $kbe, pjrt_device: $pjrt, libtpu_so_path: $libtpu_p, libtpu_mapped_so_path: $libtpu_p, libtpu_mapped_so_sha256: $sha}"
    exit /b 0
)
if not exist "!_sab_py!" (
    echo [ERROR] Python executable not found for Stage A probe: !_sab_py! 1>&2
    exit /b 1
)
set "_sab_py_tmp=%TEMP%\g4s_stage_a_%RANDOM%.py"
> "!_sab_py_tmp!" echo import hashlib, json, os, sys
>> "!_sab_py_tmp!" echo bid, prov = sys.argv[1], sys.argv[2]
>> "!_sab_py_tmp!" echo chips = 0
>> "!_sab_py_tmp!" echo dk = "CPU_FALLBACK"
>> "!_sab_py_tmp!" echo ka = os.environ.get("KERAS_BACKEND", "")
>> "!_sab_py_tmp!" echo pj = os.environ.get("PJRT_DEVICE", "")
>> "!_sab_py_tmp!" echo lp = os.environ.get("TPU_LIBRARY_PATH", "")
>> "!_sab_py_tmp!" echo if bid in ("jax_native", "maxtext", "keras_jax"):
>> "!_sab_py_tmp!" echo     import jax; devs = [d for d in jax.devices() if d.platform == "tpu"]; chips = len(devs); dk = devs[0].device_kind if devs else "CPU_FALLBACK"
>> "!_sab_py_tmp!" echo elif bid in ("hf_transformers", "pytorch_native", "keras_pytorch"):
>> "!_sab_py_tmp!" echo     import torch_xla.core.xla_model as xm; devs = xm.get_xla_supported_devices("TPU"); chips = len(devs) if devs else 0; dk = str(xm.xla_device()) if chips ^> 0 else "CPU_FALLBACK"
>> "!_sab_py_tmp!" echo elif bid == "keras_tensorflow":
>> "!_sab_py_tmp!" echo     import tensorflow as tf; tpus = tf.config.list_logical_devices("TPU"); chips = len(tpus); dk = "TPU_LOGICAL" if chips ^> 0 else "CPU_FALLBACK"
>> "!_sab_py_tmp!" echo sha = hashlib.sha256(open(lp,"rb").read()).hexdigest().lower() if lp and os.path.isfile(lp) else ""
>> "!_sab_py_tmp!" echo st = "ok" if chips ^> 0 else "failed_cpu_fallback"
>> "!_sab_py_tmp!" echo print(json.dumps({"backend_id": bid, "libtpu_provider": prov, "stage_a_status": st, "device_kind": dk, "chip_count": chips, "keras_backend_active": ka, "pjrt_device": pj, "libtpu_so_path": lp, "libtpu_mapped_so_path": lp, "libtpu_mapped_so_sha256": sha}))
>> "!_sab_py_tmp!" echo sys.exit(0 if chips ^> 0 else 65)
"!_sab_py!" "!_sab_py_tmp!" "!_sab_bid!" "!_sab_prov!"
set "_sab_pa_rc=!errorlevel!"
del /f /q "!_sab_py_tmp!" >nul 2>&1
exit /b !_sab_pa_rc!

:: ## gemma_4_sql_collect_wheel_versions
:: Queries installed framework wheel versions via importlib.metadata or emits synthetic fixture JSON in test mode.
:gemma_4_sql_collect_wheel_versions
set "_sab_py=%~1"
if "%GEMMA_4_SQL_SYNTHETIC_FIXTURES%"=="1" (
    echo {"gemma-4-sql":"0.1.0","jax":"0.4.35","libtpu":"0.0.52","torch":"2.5.1","torch_xla":"2.5.1","transformers":"4.47.0","tensorflow-tpu":"2.18.0","keras":"3.7.0","maxtext":"0.1.0","duckdb":"1.1.3"}
    exit /b 0
)
if not exist "!_sab_py!" (
    echo {}
    exit /b 0
)
set "_sab_wv_tmp=%TEMP%\g4s_wheels_%RANDOM%.py"
> "!_sab_wv_tmp!" echo import importlib.metadata as md, json
>> "!_sab_wv_tmp!" echo out = {}
>> "!_sab_wv_tmp!" echo for p in ["gemma-4-sql","jax","jaxlib","libtpu","torch","torch_xla","transformers","tensorflow-tpu","tensorflow","keras","keras-hub","maxtext","flax","duckdb"]:
>> "!_sab_wv_tmp!" echo     try: out[p] = md.version(p)
>> "!_sab_wv_tmp!" echo     except Exception: pass
>> "!_sab_wv_tmp!" echo print(json.dumps(out))
"!_sab_py!" "!_sab_wv_tmp!"
set "_sab_wv_rc=!errorlevel!"
del /f /q "!_sab_wv_tmp!" >nul 2>&1
exit /b !_sab_wv_rc!

:: ## gemma_4_sql_exec_with_stage_b
:: Executes benchmark command and enforces fail-fast exit 65 when TPU HBM activity is zero while GEMMA_4_SQL_REQUIRE_HBM=1.
:gemma_4_sql_exec_with_stage_b
set "_sab_bid=%~1"
set "_sab_cmd=%~2"
set "_sab_out=%~3"
set "_sab_req=%~4"
set "_sab_wout=%~5"
if "!_sab_req!"=="" set "_sab_req=%GEMMA_4_SQL_REQUIRE_HBM%"
if "!_sab_req!"=="" set "_sab_req=1"

cmd /c "!_sab_cmd!"
set "_sab_cmd_rc=!errorlevel!"
if not "!_sab_cmd_rc!"=="0" exit /b !_sab_cmd_rc!

set "_sab_fd=false"
set "_sab_hbm=0"
set "_sab_duty=0.0"
set "_sab_rss=0"

if "%GEMMA_4_SQL_SYNTHETIC_FIXTURES%"=="1" (
    set "_sab_fd=%TPU_MOCK_STAGE_B_FD%"
    if "!_sab_fd!"=="" set "_sab_fd=%TPU_MOCK_ACCEL_FD_OPENED%"
    if "!_sab_fd!"=="" set "_sab_fd=true"
    set "_sab_hbm=%TPU_MOCK_STAGE_B_HBM_BYTES%"
    if "!_sab_hbm!"=="" set "_sab_hbm=%TPU_MOCK_PEAK_HBM_BYTES%"
    if "!_sab_hbm!"=="" set "_sab_hbm=8589934592"
    set "_sab_duty=%TPU_MOCK_STAGE_B_DUTY_PCT%"
    if "!_sab_duty!"=="" set "_sab_duty=84.5"
    set "_sab_rss=%TPU_MOCK_STAGE_B_RSS_BYTES%"
    if "!_sab_rss!"=="" set "_sab_rss=2147483648"
) else (
    if not "!_sab_wout!"=="" (
        if exist "!_sab_wout!" (
            for /f "usebackq delims=" %%M in (`jq -r "if (.peak_memory_mb // 0) > 0 then ((.peak_memory_mb * 1048576) | floor) else 0 end" "!_sab_wout!" 2^>nul`) do set "_sab_hbm=%%M"
            if not "!_sab_hbm!"=="0" (
                if not "!_sab_hbm!"=="" set "_sab_fd=true"
            )
        )
    )
)

if "!_sab_req!"=="1" goto :check_hbm_win
if /i "!_sab_req!"=="true" goto :check_hbm_win
goto :stage_b_ok

:: ## check_hbm_win
:: Verifies non-zero TPU HBM bytes and accelerator fd status or writes failed_cpu_fallback and returns exit 65.
:check_hbm_win
if /i not "!_sab_fd!"=="true" goto :emit_fallback_65
if "!_sab_hbm!"=="0" goto :emit_fallback_65
goto :stage_b_ok

:: ## emit_fallback_65
:: Emits failed_cpu_fallback JSON artifact and exits with code 65.
:emit_fallback_65
for %%D in ("!_sab_out!") do if not exist "%%~dpD" mkdir "%%~dpD"
jq -n --arg b "!_sab_bid!" --argjson fd "!_sab_fd!" --argjson hbm "!_sab_hbm!" --argjson rss "!_sab_rss!" "{backend_id: $b, status: \"failed_cpu_fallback\", exit_code: 65, telemetry: {accelerator_fd_opened: $fd, peak_tpu_hbm_bytes: $hbm, peak_host_rss_bytes: $rss}}" > "!_sab_out!.tmp"
move /y "!_sab_out!.tmp" "!_sab_out!" >nul
echo [ERROR] Stage B CPU-fallback detected for backend "!_sab_bid!" ^(exit 65^). 1>&2
exit /b 65

:: ## stage_b_ok
:: Exports measured Stage B telemetry into caller environment variables.
:stage_b_ok
set "STAGE_B_ACCEL_FD=!_sab_fd!"
set "STAGE_B_PEAK_HBM=!_sab_hbm!"
set "STAGE_B_DUTY_PCT=!_sab_duty!"
set "STAGE_B_PEAK_HOST_RSS_BYTES=!_sab_rss!"
exit /b 0
