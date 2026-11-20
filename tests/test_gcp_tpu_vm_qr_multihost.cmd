@echo off
:: # test_gcp_tpu_vm_qr_multihost.cmd
:: ## Overview
:: Hermetic Windows Batch test suite for _lib\cloud-providers\gcp-tpu-vm\cli.cmd testing Queued Resource 2x idempotent create/delete, wait-ready polling, 1-worker/4-worker topology-info, --all-workers scp/ssh, sync-repo tree-hash skip, arm-ttl, and release-locks.
:: ## Usage
:: tests\test_gcp_tpu_vm_qr_multihost.cmd

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
set "_WDIR=!LIBSCRIPT_ROOT_DIR!\tests_tmp\tpu_qr_win_%RANDOM%"
if not exist "!_WDIR!\bin" mkdir "!_WDIR!\bin"
if not exist "!_WDIR!\state" mkdir "!_WDIR!\state"
if not exist "!_WDIR!\repo" mkdir "!_WDIR!\repo"
echo print("ok") > "!_WDIR!\repo\main.py"
set "_G_LOG=!_WDIR!\gcloud.log"
type nul > "!_G_LOG!"

(
    echo @echo off
    echo echo %%* ^>^> "!_G_LOG!"
    echo echo %%* ^| findstr /I /C:"disks describe" ^>nul ^&^& exit /b 1
    echo echo %%* ^| findstr /I /C:"queued-resources create" ^>nul ^&^& ^( type nul ^> "!_WDIR!\state\qr_exists" ^& type nul ^> "!_WDIR!\state\vm_exists" ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"queued-resources describe" ^>nul ^&^& ^( if exist "!_WDIR!\state\qr_exists" ^( echo {"state":{"state":"ACTIVE"}} ^& exit /b 0 ^) else exit /b 1 ^)
    echo echo %%* ^| findstr /I /C:"queued-resources delete" ^>nul ^&^& ^( del /f /q "!_WDIR!\state\qr_exists" 2^>nul ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"tpu-vm describe pod-v4-32" ^>nul ^&^& ^( echo {"name":"pod-v4-32","acceleratorType":"v4-32","runtimeVersion":"tpu-ubuntu2204-base","schedulingConfig":{"spot":true},"networkEndpoints":[{"ipAddress":"10.0.0.2"},{"ipAddress":"10.0.0.3"},{"ipAddress":"10.0.0.4"},{"ipAddress":"10.0.0.5"}]} ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:"tpu-vm describe" ^>nul ^&^& ^( if exist "!_WDIR!\state\vm_exists" ^( echo {"name":"node-1","state":"READY","acceleratorType":"v6e-8","runtimeVersion":"v2-alpha-tpuv6e","schedulingConfig":{"spot":true},"networkEndpoints":[{"ipAddress":"10.128.0.10"}]} ^& exit /b 0 ^) else exit /b 1 ^)
    echo echo %%* ^| findstr /I /C:"tpu-vm delete" ^>nul ^&^& ^( del /f /q "!_WDIR!\state\vm_exists" 2^>nul ^& exit /b 0 ^)
    echo echo %%* ^| findstr /I /C:".libscript_sync.sha256" ^>nul ^&^& ^( if exist "!_WDIR!\state\sync_hash" ^( type "!_WDIR!\state\sync_hash"^) else ^( echo MISSING^) ^& exit /b 0 ^)
    echo exit /b 0
) > "!_WDIR!\bin\gcloud.cmd"
set "PATH=!_WDIR!\bin;!PATH!"

set "GCP_PROJECT_ID=trc-win-proj"
set "TPU_ZONE=us-central1-a"
set "TPU_ACCELERATOR_TYPE=v6e-8"
set "TPU_SCHEDULING_TYPE=spot"
set "TPU_USE_QUEUED_RESOURCE=true"
set "_T_CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\gcp-tpu-vm\cli.cmd"

:: 1. 2x idempotent create + runtime auto-resolution (v2-alpha-tpuv6e)
call "!_T_CLI!" create node-1
if errorlevel 1 goto :fail
findstr /I /C:"--runtime-version=v2-alpha-tpuv6e" "!_G_LOG!" >nul || goto :fail
call "!_T_CLI!" create node-1
if errorlevel 1 goto :fail
set "_create_cnt=0"
for /f %%C in ('findstr /I /C:"queued-resources create" "!_G_LOG!" ^| find /c /v ""') do set "_create_cnt=%%C"
if not "!_create_cnt!"=="1" goto :fail

:: 2. wait-ready polling
set "TPU_WAIT_POLL_SEC=0"
call "!_T_CLI!" wait-ready node-1 "--poll-sec=0"
if errorlevel 1 goto :fail

:: 3. topology-info for 1-worker and 4-worker slices
call "!_T_CLI!" topology-info node-1 > "!_WDIR!\topo1.json"
jq -e ".worker_count == 1 and .worker0_internal_ip == \"10.128.0.10\"" "!_WDIR!\topo1.json" >nul || goto :fail
call "!_T_CLI!" topology-info pod-v4-32 > "!_WDIR!\topo4.json"
jq -e ".worker_count == 4 and .worker_ips == \"10.0.0.2,10.0.0.3,10.0.0.4,10.0.0.5\"" "!_WDIR!\topo4.json" >nul || goto :fail

:: 4. scp --all-workers and ssh --all-workers --forward-port
call "!_T_CLI!" scp node-1 "!_WDIR!\repo\main.py" "./main.py" --all-workers
if errorlevel 1 goto :fail
findstr /I /C:"tpu-vm scp --worker=all" "!_G_LOG!" >nul || goto :fail
call "!_T_CLI!" ssh node-1 --all-workers --forward-port 6006:6006 "echo ok"
if errorlevel 1 goto :fail
findstr /I /C:"--worker=all --ssh-flag=-L6006:6006" "!_G_LOG!" >nul || goto :fail

:: 5. sync-repo tree-hash skip on second run
for /f "usebackq delims=" %%H in (`call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\remote_sync.cmd" compute-hash "!_WDIR!\repo"`) do set "_RH=%%H"
call "!_T_CLI!" sync-repo node-1 "!_WDIR!\repo" "./workspace" --all-workers
if errorlevel 1 goto :fail
> "!_WDIR!\state\sync_hash" echo.!_RH!
type nul > "!_G_LOG!"
call "!_T_CLI!" sync-repo node-1 "!_WDIR!\repo" "./workspace" --all-workers
if errorlevel 1 goto :fail
findstr /I /C:"libscript_repo_sync.tar.gz" "!_G_LOG!" >nul && goto :fail

:: 6. arm-ttl (2x) and release-locks
call "!_T_CLI!" arm-ttl node-1 "--minutes=90"
if errorlevel 1 goto :fail
call "!_T_CLI!" arm-ttl node-1 "--minutes=120"
if errorlevel 1 goto :fail
call "!_T_CLI!" release-locks node-1
if errorlevel 1 goto :fail

:: 7. 2x delete cleans up both -qr and tpu-vm even when TPU_USE_QUEUED_RESOURCE is unset
set "TPU_USE_QUEUED_RESOURCE="
call "!_T_CLI!" delete node-1
if errorlevel 1 goto :fail
if exist "!_WDIR!\state\qr_exists" goto :fail
if exist "!_WDIR!\state\vm_exists" goto :fail
call "!_T_CLI!" delete node-1
if errorlevel 1 goto :fail

rmdir /s /q "!_WDIR!" >nul 2>&1
echo [PASS] All Windows GCP TPU VM Queued Resource and multi-host tests passed^^!
exit /b 0

:: ## fail
:: Cleans up temporary test directory and exits non-zero on failure.
:fail
rmdir /s /q "!_WDIR!" >nul 2>&1
echo [FAIL] Windows GCP TPU VM Queued Resource test failed^^! 1>&2
exit /b 1
