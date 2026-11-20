@echo off
:: # test_tpu_k8s_gcs_stack.cmd
:: ## Overview
:: Windows Batch integration test suite verifying Pillar 3 (`ML-01`..`ML-15`): GKE+TPU topology
:: convergence and dynamic scaling, 4-role GCS ML storage coordination + TFRC cross-region rejection,
:: and `tpu_vm`/`xpk` payload schedulers.
:: ## Usage
:: .\tests\test_tpu_k8s_gcs_stack.cmd

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
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## fail_ml
:: Reports test failure, cleans up temporary directory, and exits 1.
:fail_ml
echo [FAIL] %~1 1>&2
if exist "%TEST_TMP%" rmdir /s /q "%TEST_TMP%" >nul 2>&1
exit /b 1

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "TEST_TMP=%TEMP%\libscript_ml_test_%RANDOM%"
if not exist "%TEST_TMP%" mkdir "%TEST_TMP%"
set "LIBSCRIPT_DATA_DIR=%TEST_TMP%\state"

echo === 1. GKE+TPU Topology Convergence, Dynamic Scale, ^& Choreography Checkpoints ===
set "LIBSCRIPT_TOPOLOGY_STATE_DIR=%TEST_TMP%\gke_topo"
call "%LIBSCRIPT_ROOT_DIR%\topologies\engine.cmd" up "%LIBSCRIPT_ROOT_DIR%\topologies\gke-tpu-cluster\topology.json" >nul
if errorlevel 1 ( call :fail_ml "Initial topology up failed" & exit /b 1 )
call "%LIBSCRIPT_ROOT_DIR%\topologies\engine.cmd" up "%LIBSCRIPT_ROOT_DIR%\topologies\gke-tpu-cluster\topology.json" >nul
if errorlevel 1 ( call :fail_ml "Idempotent 2x topology up failed" & exit /b 1 )

jq -e ".status == \"HEALTHY\" and (.completed_hooks | length == 5)" "%LIBSCRIPT_TOPOLOGY_STATE_DIR%\.topology_state.json" >nul
if errorlevel 1 ( call :fail_ml "Topology choreography hooks not recorded" & exit /b 1 )

call "%LIBSCRIPT_ROOT_DIR%\topologies\engine.cmd" scale "%LIBSCRIPT_ROOT_DIR%\topologies\gke-tpu-cluster\topology.json" "tpu-slice-pool=4" >nul
if errorlevel 1 ( call :fail_ml "Topology scale failed" & exit /b 1 )

jq -e "[.nodes[] | select(.group == \"tpu-slice-pool\")] | length == 4" "%LIBSCRIPT_TOPOLOGY_STATE_DIR%\.topology_state.json" >nul
if errorlevel 1 ( call :fail_ml "Dynamic topology scale failed to reconcile node count to 4" & exit /b 1 )

echo === 2. 4-Role GCS ML Storage Synthesis ^& TFRC Same-Region Verification ===
if not exist "%TEST_TMP%\bin" mkdir "%TEST_TMP%\bin"
(
    echo @echo off
    echo echo %%* ^| findstr /C:"buckets describe gs://tfrc-us-central2" ^>nul 2^>^&1
    echo if not errorlevel 1 ^( echo {"name":"tfrc-us-central2","location":"US-CENTRAL2","locationType":"region"} ^& exit /b 0 ^)
    echo echo %%* ^| findstr /C:"buckets describe gs://wrong-eu-west4" ^>nul 2^>^&1
    echo if not errorlevel 1 ^( echo {"name":"wrong-eu-west4","location":"EUROPE-WEST4","locationType":"region"} ^& exit /b 0 ^)
    echo echo %%* ^| findstr /C:"config get-value project" ^>nul 2^>^&1
    echo if not errorlevel 1 ^( echo trc-ml-proj ^& exit /b 0 ^)
    echo exit /b 0
) > "%TEST_TMP%\bin\gcloud.cmd"

(
    echo {"schema_version":"1.0","gcp_project_id":"trc-ml-proj","strict_zero_cost":true,"storage_mode":"same_region_gcs","allowed_gcs_buckets":["gs://tfrc-us-central2"],"grants":[{"zone":"us-central2-b","accelerator_types":["v4-8","v4-32"],"scheduling_tiers":["spot"],"max_chips":16,"max_hosts":4,"max_concurrent_nodes":2}]}
) > "%TEST_TMP%\tfrc.policy.json"

(
    echo {"ml":{"target":"gcp-tpu-vm","backend":"jax_native","gcs_storage":{"zone":"us-central2-b","datasets":[{"name":"fineweb","uri":"gs://tfrc-us-central2/datasets/fineweb","format":"arrayrecord"}],"checkpoints":{"uri":"gs://tfrc-us-central2/checkpoints/gemma4","retention_days":14,"async_save":true},"xla_compilation_cache":{"uri":"gs://tfrc-us-central2/xla-cache"},"fuse_mounts":[{"bucket":"gs://tfrc-us-central2","mount_path":"/mnt/weights","workload_identity_ksa":"ml-trainer-ksa"}]}}}
) > "%TEST_TMP%\ml-manifest.json"

set "ORIG_PATH=%PATH%"
set "PATH=%TEST_TMP%\bin;%PATH%"
set "TFRC_CONFIG=%TEST_TMP%\tfrc.policy.json"
set "GCP_PROJECT_ID=trc-ml-proj"

call "%LIBSCRIPT_ROOT_DIR%\traits\storage\gcs_ml.cmd" "%TEST_TMP%\ml-manifest.json" "--out-dir=%TEST_TMP%\gcs_out" --dry-run >nul
if errorlevel 1 ( set "PATH=%ORIG_PATH%" & call :fail_ml "gcs_ml.cmd valid same-region run failed" & exit /b 1 )

findstr /C:"JAX_COMPILATION_CACHE_DIR" "%TEST_TMP%\gcs_out\tpu-gcs-env.sh" >nul 2>&1
if errorlevel 1 ( set "PATH=%ORIG_PATH%" & call :fail_ml "Missing JAX_COMPILATION_CACHE_DIR export" & exit /b 1 )

(
    echo {"ml":{"target":"gcp-tpu-vm","backend":"jax_native","gcs_storage":{"zone":"us-central2-b","datasets":[{"name":"fineweb","uri":"gs://wrong-eu-west4/datasets/fineweb","format":"arrayrecord"}]}}}
) > "%TEST_TMP%\bad-gcs.json"

call "%LIBSCRIPT_ROOT_DIR%\traits\storage\gcs_ml.cmd" "%TEST_TMP%\bad-gcs.json" "--out-dir=%TEST_TMP%\gcs_bad" --dry-run >nul 2>&1
if not errorlevel 1 ( set "PATH=%ORIG_PATH%" & call :fail_ml "Expected TFRC cross-region GCS bucket to be rejected!" & exit /b 1 )
set "PATH=%ORIG_PATH%"

echo === 3. Unified tpu_vm ^& xpk Payload Scheduler Lifecycle ===
call "%LIBSCRIPT_ROOT_DIR%\payloads\engine.cmd" compile "%LIBSCRIPT_ROOT_DIR%\payloads\ai\gcp-tpu-vm\payload.json" --scheduler=tpu_vm > "%TEST_TMP%\compile.json"
if errorlevel 1 ( call :fail_ml "tpu_vm compile failed" & exit /b 1 )
jq -e ".scheduler == \"tpu_vm\" and .sync_mode == \"tree-hash-all-workers\"" "%TEST_TMP%\compile.json" >nul
if errorlevel 1 ( call :fail_ml "tpu_vm compile output assertion failed" & exit /b 1 )

call "%LIBSCRIPT_ROOT_DIR%\payloads\engine.cmd" submit "%LIBSCRIPT_ROOT_DIR%\payloads\ai\gcp-tpu-vm\payload.json" --scheduler=tpu_vm --dry-run > "%TEST_TMP%\submit.json"
if errorlevel 1 ( call :fail_ml "tpu_vm submit failed" & exit /b 1 )
jq -e ".status == \"ok\"" "%TEST_TMP%\submit.json" >nul
if errorlevel 1 ( call :fail_ml "tpu_vm submit status assertion failed" & exit /b 1 )

call "%LIBSCRIPT_ROOT_DIR%\payloads\engine.cmd" destroy "%LIBSCRIPT_ROOT_DIR%\payloads\ai\gcp-tpu-vm\payload.json" --scheduler=tpu_vm --dry-run > "%TEST_TMP%\destroy.json"
if errorlevel 1 ( call :fail_ml "tpu_vm destroy failed" & exit /b 1 )
jq -e ".status == \"ok\"" "%TEST_TMP%\destroy.json" >nul
if errorlevel 1 ( call :fail_ml "tpu_vm destroy status assertion failed" & exit /b 1 )

rmdir /s /q "%TEST_TMP%" >nul 2>&1
echo [PASS] All Pillar 3 ML / TPU / Kubernetes / GCS stack tests passed^^!
exit /b 0
