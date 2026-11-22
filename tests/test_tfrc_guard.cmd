@echo off
:: # test_tfrc_guard.cmd
:: ## Overview
:: Hermetic Windows Batch test suite for engine\common\tfrc_guard.cmd verifying missing config, project mismatch, UTC expiry, SKU/zone/tier bounds, GKE/Artifact Registry blocks, disk stripping, GCS region parity, postflight audit, and 2x idempotency.
:: ## Usage
:: tests\test_tfrc_guard.cmd

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
set "_WDIR=!LIBSCRIPT_ROOT_DIR!\tests_tmp\tfrc_guard_win_%RANDOM%"
if not exist "!_WDIR!\bin" mkdir "!_WDIR!\bin"
if not exist "!_WDIR!\empty_repo" mkdir "!_WDIR!\empty_repo"
set "GCLOUD_LOG=!_WDIR!\gcloud_calls.log"
type nul > "!GCLOUD_LOG!"

(
    echo @echo off
    echo echo %%* ^>^> "%%GCLOUD_LOG%%"
    echo echo %%* ^| findstr /I /C:"config get-value project" ^>nul ^&^& ^( if defined MOCK_GCLOUD_PROJECT ^( echo %%MOCK_GCLOUD_PROJECT%%^) else ^( echo my-trc-research-project^) ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"gs://valid-us-central2" ^>nul ^&^& ^( echo {"locationType":"region","location":"US-CENTRAL2"} ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"gs://multi-us-bucket" ^>nul ^&^& ^( echo {"locationType":"multi-region","location":"US"} ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"gs://wrong-region-east1" ^>nul ^&^& ^( echo {"locationType":"region","location":"US-EAST1"} ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"tpu-vm list" ^>nul ^&^& ^( if "%%MOCK_LEAKED_TPU%%"=="1" ^( echo [{"name":"projects/p/locations/us-central2-b/nodes/leaked-node","state":"READY"}]^) else ^( echo []^) ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"list" ^>nul ^&^& ^( echo [] ^& exit /b 0 ^)
    echo exit /b 0
) > "!_WDIR!\bin\gcloud.cmd"
set "PATH=!_WDIR!\bin;!PATH!"

set "_POL=!_WDIR!\tfrc.policy.json"
jq -n "{schema_version:\"1.0\",gcp_project_id:\"my-trc-research-project\",strict_zero_cost:true,storage_mode:\"ssh\",max_ttl_minutes:180,shm_min_free_gb:32,grants:[{zone:\"us-central2-b\",accelerator_types:[\"v4-8\",\"v4-16\",\"v4-32\"],scheduling_tiers:[\"on-demand\",\"spot\",\"preemptible\"],max_hosts:4,max_chips:16,max_concurrent_nodes:1,expires_on:\"2026-12-14\"},{zone:\"us-central1-a\",accelerator_types:[\"v5litepod-8\",\"v6e-8\"],scheduling_tiers:[\"spot\"],max_hosts:2,max_chips:16,max_concurrent_nodes:1,expires_on:\"2026-12-14\"}]}" > "!_POL!"

:: 1. Missing TFRC_CONFIG -> exits 78 before any gcloud call
pushd "!_WDIR!\empty_repo"
set "TFRC_CONFIG="
set "LIBSCRIPT_TFRC_CONFIG="
set "TFRC_STRICT=1"
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\providers\gcp-tpu-vm\cli.cmd" create test-node >nul 2>&1
set "_rc=!ERRORLEVEL!"
popd
if not "!_rc!"=="78" goto :fail
REM wincheck disable=CMD2003
for %%S in ("!GCLOUD_LOG!") do if %%~zS gtr 0 goto :fail

:: 2. Project mismatch -> exits 78
set "TFRC_CONFIG=!_POL!"
set "TFRC_MOCK_UTC_DATE=2026-11-14"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_validate_request "wrong-proj" "us-central2-b" "v4-8" "spot" "1" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail

:: 3. Expired grant -> exits 78
set "TFRC_MOCK_UTC_DATE=2027-02-01"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_validate_request "my-trc-research-project" "us-central2-b" "v4-8" "spot" "1" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail

:: 4. Disallowed zone, SKU, chip bound, and on-demand tier on Spot-only grant -> exits 78
set "TFRC_MOCK_UTC_DATE=2026-11-14"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_validate_request "my-trc-research-project" "europe-west4-a" "v4-8" "spot" "1" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_validate_request "my-trc-research-project" "us-central2-b" "v5p-8" "spot" "1" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_validate_request "my-trc-research-project" "us-central2-b" "v4-64" "spot" "1" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_validate_request "my-trc-research-project" "us-central1-a" "v6e-8" "on-demand" "1" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail

:: 5. gke-xpk targets blocked with 78
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\clusters\gke-tpu-cluster\cli.cmd" create bad-cluster >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" train --tfrc-only "--target=gke-xpk" --dry-run >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail

:: 6. DISK_SIZE_GB=500 / TPU_DATA_DISK_SIZE=500 stripped and 2x idempotent
type nul > "!GCLOUD_LOG!"
set "DISK_SIZE_GB=500"
set "TPU_DATA_DISK_SIZE=500"
set "BUCKET_NAME=manifest-bucket"
set "GCS_BUCKET=gs://manifest-bucket"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
if errorlevel 1 goto :fail
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
if errorlevel 1 goto :fail
if not "!DISK_SIZE_GB!"=="" goto :fail
if not "!TPU_DATA_DISK_SIZE!"=="" goto :fail
if not "!GCS_BUCKET!"=="" goto :fail

set "GCP_PROJECT_ID=my-trc-research-project"
set "TPU_ZONE=us-central2-b"
set "TPU_ACCELERATOR_TYPE=v4-8"
set "TPU_SCHEDULING_TYPE=spot"
set "DISK_SIZE_GB=500"
set "TPU_DATA_DISK_SIZE=500"
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\providers\gcp-tpu-vm\cli.cmd" create tfrc-ok-node
if errorlevel 1 goto :fail
findstr /I /C:"disks create" "!GCLOUD_LOG!" >nul 2>&1
if not errorlevel 1 goto :fail

:: 7. GCS bucket region parity: matching single-region passes; multi-region & wrong-region exit 78
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_verify_gcs_bucket "gs://valid-us-central2" "us-central2-b"
if errorlevel 1 goto :fail
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_verify_gcs_bucket "gs://multi-us-bucket" "us-central2-b" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_verify_gcs_bucket "gs://wrong-region-east1" "us-central2-b" >nul 2>&1
if not "!ERRORLEVEL!"=="78" goto :fail

:: 8. Postflight audit passes when clean and fails when leaked node exists
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_postflight_audit "my-trc-research-project" "us-central2-b" "leaked-node"
if errorlevel 1 goto :fail
set "MOCK_LEAKED_TPU=1"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\tfrc_guard.cmd" :libscript_tfrc_postflight_audit "my-trc-research-project" "us-central2-b" "leaked-node" >nul 2>&1
if not errorlevel 1 goto :fail

rmdir /s /q "!_WDIR!" >nul 2>&1
echo [PASS] All Windows TFRC zero-cost guardrail tests passed^^!
exit /b 0

:: ## fail
:: Cleans up temporary test workspace and exits with status 1 on assertion failure.
:fail
rmdir /s /q "!_WDIR!" >nul 2>&1
echo [FAIL] Windows TFRC zero-cost guardrail test failed^^! 1>&2
exit /b 1
