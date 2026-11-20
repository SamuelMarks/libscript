@echo off
:: # cli.cmd
:: ## Overview
:: Command-line interface for managing single-host and multi-host GCP Cloud TPU VMs and Queued Resources with TFRC zero-cost guardrails on Windows.
:: ## Usage
:: libscript.cmd gcp-tpu-vm <create|delete|start|stop|status|ssh|scp|profile|wait-ready|topology-info|sync-repo|arm-ttl|release-locks|tfrc-audit> [args...]

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
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

set "LOG_CMD=%~dp0..\..\_common\log.cmd"
set "TFRC_GUARD_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\ml-training\_common\tfrc_guard.cmd"
set "REMOTE_SYNC_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\remote_sync.cmd"

if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help
if "%~1"=="-?" goto :show_help

if /i "%~1"=="install" (
    call "%~dp0setup.cmd" %*
    exit /b !errorlevel!
)
if /i "%~1"=="test" (
    call "%~dp0test.cmd" %*
    exit /b !errorlevel!
)
for %%V in (logs use env ls ls-remote download uninstall install-service uninstall-service which exec run) do (
    if /i "%~1"=="%%V" (
        echo [ERROR] Action '%%V' requires capability 'versioned-artifact' or 'service-daemon' ^(gcp-tpu-vm capabilities: ["cloud-operator"]^). >&2
        exit /b 1
    )
)

set "ACTION=%~1"
if /i "%ACTION%"=="tfrc-audit" goto :tfrc_audit

where gcloud >nul 2>&1
if errorlevel 1 (
    call "!LOG_CMD!" :log_error "gcloud not found in PATH. Please install the gcp-cli component first."
    exit /b 1
)

set "TPU_NAME=%~2"
if "%TPU_COUNT%"=="" set "TPU_COUNT=1"
if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"
if "%TPU_SCHEDULING_TYPE%"=="" set "TPU_SCHEDULING_TYPE=on-demand"

set "_TPU_TFRC=0"
if "%TFRC_STRICT%"=="1" set "_TPU_TFRC=1"
if "%LIBSCRIPT_TFRC_STRICT%"=="1" set "_TPU_TFRC=1"
if not "%TFRC_CONFIG%"=="" set "_TPU_TFRC=1"
if not "%LIBSCRIPT_TFRC_CONFIG%"=="" set "_TPU_TFRC=1"

if "!_TPU_TFRC!"=="1" (
    call "!TFRC_GUARD_CMD!" :libscript_tfrc_require_config
    if errorlevel 1 exit /b !errorlevel!
    if "%GCP_PROJECT_ID%"=="" (
        for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "GCP_PROJECT_ID=%%P"
    )
    call "!TFRC_GUARD_CMD!" :libscript_tfrc_enforce_zero_cost_env
    if errorlevel 1 exit /b !errorlevel!
)

if "%TPU_ZONE%"=="" (
    call "!LOG_CMD!" :log_error "TPU_ZONE must be explicitly specified."
    exit /b 1
)
if "%GCP_PROJECT_ID%"=="" (
    call "!LOG_CMD!" :log_error "GCP_PROJECT_ID must be explicitly specified to prevent accidental provisioning."
    exit /b 1
)
set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

call :resolve_tpu_runtime_version "%TPU_ACCELERATOR_TYPE%" "%TPU_VERSION%"

set "SCHEDULING_FLAG="
if /i "%TPU_SCHEDULING_TYPE%"=="spot" set "SCHEDULING_FLAG=--spot"
if /i "%TPU_SCHEDULING_TYPE%"=="preemptible" set "SCHEDULING_FLAG=--preemptible"
if "%TPU_DATA_DISK_TYPE%"=="" set "TPU_DATA_DISK_TYPE=pd-balanced"

if /i "%ACTION%"=="create" goto :create
if /i "%ACTION%"=="delete" goto :delete
if /i "%ACTION%"=="start" goto :start
if /i "%ACTION%"=="stop" goto :stop
if /i "%ACTION%"=="ssh" goto :ssh
if /i "%ACTION%"=="scp" goto :scp
if /i "%ACTION%"=="scp-from" goto :scp
if /i "%ACTION%"=="profile" goto :profile
if /i "%ACTION%"=="status" goto :status
if /i "%ACTION%"=="wait-ready" goto :wait_ready
if /i "%ACTION%"=="topology-info" goto :topology_info
if /i "%ACTION%"=="sync-repo" goto :sync_repo
if /i "%ACTION%"=="arm-ttl" goto :arm_ttl
if /i "%ACTION%"=="release-locks" goto :release_locks

call "!LOG_CMD!" :log_error "Unknown action: %ACTION%"
exit /b 1

:: ## show_help
:: Prints usage instructions for cli.cmd.
:show_help
echo Usage: %~nx0 ^<create^|delete^|start^|stop^|status^|ssh^|scp^|profile^|wait-ready^|topology-info^|sync-repo^|arm-ttl^|release-locks^|tfrc-audit^> [args...]
echo See README.md for details.
exit /b 0

:: ## resolve_tpu_runtime_version
:: Resolves TPU_VERSION automatically from TPU_ACCELERATOR_TYPE when unset or 'auto'.
:resolve_tpu_runtime_version
set "_rt_sku=%~1"
set "_rt_ver=%~2"
if not "!_rt_ver!"=="" if /i not "!_rt_ver!"=="auto" (
    set "TPU_VERSION=!_rt_ver!"
    exit /b 0
)
set "TPU_VERSION=tpu-ubuntu2204-base"
if /i "!_rt_sku:~0,9!"=="v5litepod" set "TPU_VERSION=v2-alpha-tpuv5-lite"
if /i "!_rt_sku:~0,4!"=="v5e-" set "TPU_VERSION=v2-alpha-tpuv5-lite"
if /i "!_rt_sku:~0,4!"=="v5p-" set "TPU_VERSION=v2-alpha-tpuv5"
if /i "!_rt_sku:~0,4!"=="v6e-" set "TPU_VERSION=v2-alpha-tpuv6e"
exit /b 0

:: ## run_qr_gcloud
:: Executes GA gcloud compute tpus queued-resources with fallback to alpha.
:run_qr_gcloud
call gcloud compute tpus queued-resources %* 2>nul
if not errorlevel 1 exit /b 0
call gcloud alpha compute tpus queued-resources %*
exit /b !errorlevel!

:: ## tfrc_audit
:: Runs pre-flight or post-flight TFRC resource audits across configured zones.
:tfrc_audit
shift
set "_audit_mode=preflight"
set "_audit_name="
goto :tfrc_audit_args
:: ## tfrc_audit_args
:: Parses CLI options for the tfrc-audit subcommand.
:tfrc_audit_args
if "%~1"=="" goto :tfrc_audit_exec
set "_aa=%~1"
if /i "!_aa!"=="--postflight" (
    set "_audit_mode=postflight"
    shift
    goto :tfrc_audit_args
)
if /i "!_aa!"=="--preflight" (
    set "_audit_mode=preflight"
    shift
    goto :tfrc_audit_args
)
if "!_aa:~0,14!"=="--tfrc-config=" (
    set "TFRC_CONFIG=!_aa:~14!"
    shift
    goto :tfrc_audit_args
)
if /i "!_aa!"=="--tfrc-config" (
    set "TFRC_CONFIG=%~2"
    shift
    shift
    goto :tfrc_audit_args
)
set "_audit_name=!_aa!"
shift
goto :tfrc_audit_args

:: ## tfrc_audit_exec
:: Dispatches the requested TFRC audit mode across TPU_ZONE or all grants[].zone entries via tfrc_guard.cmd.
:tfrc_audit_exec
call "!TFRC_GUARD_CMD!" :libscript_tfrc_require_config
if errorlevel 1 exit /b !errorlevel!
if "%GCP_PROJECT_ID%"=="" for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "GCP_PROJECT_ID=%%P"
if not "%TPU_ZONE%"=="" (
    call :tfrc_audit_single_zone "%TPU_ZONE%"
    if errorlevel 1 exit /b !errorlevel!
) else (
    for /f "usebackq delims=" %%Z in (`jq -r ".grants[].zone" "!TFRC_CONFIG!"`) do (
        call :tfrc_audit_single_zone "%%Z"
        if errorlevel 1 exit /b !errorlevel!
    )
)
echo {"status":"ok","mode":"!_audit_mode!","project":"!GCP_PROJECT_ID!"}
exit /b 0

:: ## tfrc_audit_single_zone
:: Runs preflight or postflight audit for a single GCP zone.
:tfrc_audit_single_zone
set "_az=%~1"
if /i "!_audit_mode!"=="postflight" (
    call "!TFRC_GUARD_CMD!" :libscript_tfrc_postflight_audit "!GCP_PROJECT_ID!" "!_az!" "!_audit_name!"
    exit /b !errorlevel!
)
call "!TFRC_GUARD_CMD!" :libscript_tfrc_preflight_audit "!GCP_PROJECT_ID!" "!_az!" "!_audit_name!"
exit /b !errorlevel!

:: ## create
:: Creates and provisions the requested Cloud TPU VM or Queued Resource idempotently, recreating FAILED/SUSPENDED nodes.
:create
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm create <name>"
    exit /b 1
)
if "!_TPU_TFRC!"=="1" (
    call "!TFRC_GUARD_CMD!" :libscript_tfrc_validate_request "!GCP_PROJECT_ID!" "%TPU_ZONE%" "%TPU_ACCELERATOR_TYPE%" "%TPU_SCHEDULING_TYPE%" "%TPU_COUNT%"
    if errorlevel 1 exit /b !errorlevel!
    call "!TFRC_GUARD_CMD!" :libscript_tfrc_preflight_audit "!GCP_PROJECT_ID!" "%TPU_ZONE%" "%TPU_NAME%"
    if errorlevel 1 exit /b !errorlevel!
)
set "i=1"
goto :create_loop
:: ## create_loop
:: Iterates across TPU_COUNT to provision or idempotently reuse each requested node or slice.
:create_loop
REM wincheck disable=CMD2003
if !i! gtr %TPU_COUNT% exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
REM wincheck disable=CMD2003
if %TPU_COUNT% gtr 1 set "INSTANCE_NAME=%TPU_NAME%-!i!"

set "DISK_FLAG="
if not "!TPU_DATA_DISK_SIZE!"=="" (
    if "!_TPU_TFRC!"=="1" (
        echo [TFRC-GUARD] [VIOLATION] Persistent disks are forbidden in TFRC zero-cost mode. 1>&2
        exit /b 78
    )
    set "DISK_FLAG=--data-disk=source=projects/%GCP_PROJECT_ID%/zones/%TPU_ZONE%/disks/!INSTANCE_NAME!-data,mode=read-write"
    call gcloud compute disks describe "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
    if errorlevel 1 (
        call gcloud compute disks create "!INSTANCE_NAME!-data" --size="!TPU_DATA_DISK_SIZE!GB" --type="%TPU_DATA_DISK_TYPE%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    )
)

set "NETWORK_FLAG="
if not "%TPU_NETWORK%"=="" set "NETWORK_FLAG=--network=%TPU_NETWORK%"
if not "%TPU_SUBNETWORK%"=="" set "NETWORK_FLAG=!NETWORK_FLAG! --subnetwork=%TPU_SUBNETWORK%"

if /i "!TPU_USE_QUEUED_RESOURCE!"=="true" goto :create_qr_branch
goto :create_vm_branch

:: ## create_qr_branch
:: Inspects existing Queued Resource state and reuses ACTIVE/PROVISIONING or recreates FAILED/SUSPENDED resources.
:create_qr_branch
set "_qr_tmp=%TEMP%\tpu_qr_desc_%RANDOM%.json"
call :run_qr_gcloud describe "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% --format=json > "!_qr_tmp!" 2>nul
if not errorlevel 1 (
    set "_qr_state=ACTIVE"
    for /f "usebackq delims=" %%S in (`jq -r ".state.state // .state // \"ACTIVE\"" "!_qr_tmp!" 2^>nul`) do set "_qr_state=%%S"
    del /f /q "!_qr_tmp!" >nul 2>&1
    if /i "!_qr_state!"=="FAILED" goto :recreate_qr
    if /i "!_qr_state!"=="SUSPENDED" goto :recreate_qr
    call "!LOG_CMD!" :log_info "TPU Queued Resource !INSTANCE_NAME!-qr already exists in state=!_qr_state!; reusing idempotently."
    goto :create_next
)
del /f /q "!_qr_tmp!" >nul 2>&1
goto :do_create_qr

:: ## recreate_qr
:: Deletes a FAILED or SUSPENDED Queued Resource and backing TPU VM prior to recreation.
:recreate_qr
call "!LOG_CMD!" :log_info "Existing Queued Resource !INSTANCE_NAME!-qr is in state=!_qr_state!; deleting before recreate..."
call :run_qr_gcloud delete "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% --force --quiet >nul 2>&1 || rem
call gcloud compute tpus tpu-vm delete "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet >nul 2>&1 || rem
goto :do_create_qr

:: ## do_create_qr
:: Invokes gcloud compute tpus queued-resources create for the target node.
:do_create_qr
call "!LOG_CMD!" :log_info "Creating TPU Queued Resource !INSTANCE_NAME!-qr (%TPU_ACCELERATOR_TYPE%, runtime=!TPU_VERSION!) in %TPU_ZONE%..."
call :run_qr_gcloud create "!INSTANCE_NAME!-qr" --node-id="!INSTANCE_NAME!" --zone="%TPU_ZONE%" --accelerator-type="%TPU_ACCELERATOR_TYPE%" --runtime-version="!TPU_VERSION!" %SCHEDULING_FLAG% !DISK_FLAG! !NETWORK_FLAG! %PROJECT_FLAG%
if errorlevel 1 (
    call "!LOG_CMD!" :log_error "Queued Resource Provisioning failed."
    exit /b 1
)
goto :create_next

:: ## create_vm_branch
:: Inspects existing direct TPU VM state and reuses READY/CREATING or recreates TERMINATED/STOPPED/PREEMPTED VMs.
:create_vm_branch
set "_vm_tmp=%TEMP%\tpu_vm_desc_%RANDOM%.json"
call gcloud compute tpus tpu-vm describe "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% --format=json > "!_vm_tmp!" 2>nul
if not errorlevel 1 (
    set "_vm_state=READY"
    for /f "usebackq delims=" %%S in (`jq -r ".state // \"READY\"" "!_vm_tmp!" 2^>nul`) do set "_vm_state=%%S"
    del /f /q "!_vm_tmp!" >nul 2>&1
    if /i "!_vm_state!"=="TERMINATED" goto :recreate_vm
    if /i "!_vm_state!"=="STOPPED" goto :recreate_vm
    if /i "!_vm_state!"=="PREEMPTED" goto :recreate_vm
    call "!LOG_CMD!" :log_info "TPU VM !INSTANCE_NAME! already exists in state=!_vm_state!; reusing idempotently."
    goto :create_next
)
del /f /q "!_vm_tmp!" >nul 2>&1
goto :do_create_vm

:: ## recreate_vm
:: Deletes a TERMINATED, STOPPED, or PREEMPTED TPU VM prior to recreation.
:recreate_vm
call "!LOG_CMD!" :log_info "Existing TPU VM !INSTANCE_NAME! is in state=!_vm_state!; deleting before recreate..."
call gcloud compute tpus tpu-vm delete "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet >nul 2>&1 || rem
goto :do_create_vm

:: ## do_create_vm
:: Invokes gcloud compute tpus tpu-vm create for the target node.
:do_create_vm
call "!LOG_CMD!" :log_info "Creating TPU VM !INSTANCE_NAME! (%TPU_ACCELERATOR_TYPE%, version=!TPU_VERSION!) in %TPU_ZONE%..."
call gcloud compute tpus tpu-vm create "!INSTANCE_NAME!" --zone="%TPU_ZONE%" --accelerator-type="%TPU_ACCELERATOR_TYPE%" --version="!TPU_VERSION!" %SCHEDULING_FLAG% !DISK_FLAG! !NETWORK_FLAG! %PROJECT_FLAG%
if errorlevel 1 (
    call "!LOG_CMD!" :log_error "Provisioning failed."
    exit /b 1
)
:: wincheck disable=CMD3005

:: ## create_next
:: Advances the node counter during multi-slice provisioning.
:create_next
set /a i+=1
goto :create_loop

:: ## delete
:: Idempotently deletes both Queued Resources and TPU VMs without leaking -qr entries.
:delete
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm delete <name> [--all]"
    exit /b 1
)
shift
shift
set "ALL_FLAG="
goto :del_arg_loop
:: ## del_arg_loop
:: Parses command-line flags for the delete subcommand.
:del_arg_loop
if "%~1"=="" goto :del_start
if /i "%~1"=="--all" set "ALL_FLAG=true"
shift
goto :del_arg_loop

:: ## del_start
:: Initializes loop bounds for node and Queued Resource deletion.
:del_start
set "i=1"
set "LIMIT=%TPU_COUNT%"
if not "%ALL_FLAG%"=="true" set "LIMIT=1"
goto :del_loop
:: ## del_loop
:: Iterates over target node names and deletes Queued Resources, TPU VMs, and LibScript-labeled disks idempotently.
:del_loop
REM wincheck disable=CMD2003
if !i! gtr !LIMIT! exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
REM wincheck disable=CMD2003
if !LIMIT! gtr 1 if %TPU_COUNT% gtr 1 set "INSTANCE_NAME=%TPU_NAME%-!i!"

call :run_qr_gcloud describe "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if not errorlevel 1 (
    call "!LOG_CMD!" :log_info "Deleting TPU Queued Resource !INSTANCE_NAME!-qr..."
    call :run_qr_gcloud delete "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet --force >nul 2>&1 || rem
)

call gcloud compute tpus tpu-vm describe "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if not errorlevel 1 (
    call "!LOG_CMD!" :log_info "Deleting TPU VM !INSTANCE_NAME! in zone %TPU_ZONE%..."
    call gcloud compute tpus tpu-vm delete "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet >nul 2>&1 || rem
)

call gcloud compute disks describe "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if not errorlevel 1 (
    call gcloud compute disks delete "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet >nul 2>&1 || rem
)
set /a i+=1
goto :del_loop

:: ## start
:: Starts stopped Cloud TPU VM instances.
:start
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm start <name> [--all]"
    exit /b 1
)
call gcloud compute tpus tpu-vm start "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
exit /b 0

:: ## stop
:: Stops running Cloud TPU VM instances.
:stop
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm stop <name> [--all]"
    exit /b 1
)
call gcloud compute tpus tpu-vm stop "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
exit /b 0

:: ## wait_ready
:: Polls Queued Resource state (WAITING_FOR_RESOURCES -> PROVISIONING -> ACTIVE) and verifies SSH across all workers.
:wait_ready
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm wait-ready <name> [--timeout-sec 1800] [--poll-sec 15]"
    exit /b 1
)
shift
shift
set "WAIT_TIMEOUT=%TPU_WAIT_TIMEOUT_SEC%"
if "!WAIT_TIMEOUT!"=="" set "WAIT_TIMEOUT=1800"
set "WAIT_POLL=%TPU_WAIT_POLL_SEC%"
if "!WAIT_POLL!"=="" set "WAIT_POLL=15"
goto :wait_ready_args
:: ## wait_ready_args
:: Parses --timeout-sec and --poll-sec flags for wait-ready.
:wait_ready_args
if "%~1"=="" goto :wait_ready_poll_init
set "_wa=%~1"
if "!_wa:~0,14!"=="--timeout-sec=" (
    set "WAIT_TIMEOUT=!_wa:~14!"
    shift
    goto :wait_ready_args
)
if /i "!_wa!"=="--timeout-sec" (
    set "WAIT_TIMEOUT=%~2"
    shift
    shift
    goto :wait_ready_args
)
if "!_wa:~0,11!"=="--poll-sec=" (
    set "WAIT_POLL=!_wa:~11!"
    shift
    goto :wait_ready_args
)
if /i "!_wa!"=="--poll-sec" (
    set "WAIT_POLL=%~2"
    shift
    shift
    goto :wait_ready_args
)
shift
goto :wait_ready_args

:: ## wait_ready_poll_init
:: Initializes elapsed timer and polls Queued Resource or TPU VM state until ACTIVE/READY.
:wait_ready_poll_init
set "ELAPSED=0"
set /a "POLL_STEP=!WAIT_POLL!"
REM wincheck disable=CMD2003
if !POLL_STEP! lss 1 set "POLL_STEP=1"
goto :wait_ready_poll

:: ## wait_ready_poll
:: Checks Queued Resource state on each poll iteration and aborts immediately on FAILED or SUSPENDED.
:wait_ready_poll
set "_wr_tmp=%TEMP%\tpu_wr_%RANDOM%.json"
call :run_qr_gcloud describe "%TPU_NAME%-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% --format=json > "!_wr_tmp!" 2>nul
if errorlevel 1 (
    del /f /q "!_wr_tmp!" >nul 2>&1
    goto :wait_ready_ssh_init
)
set "_wr_state=UNKNOWN"
for /f "usebackq delims=" %%S in (`jq -r ".state.state // .state // \"UNKNOWN\"" "!_wr_tmp!" 2^>nul`) do set "_wr_state=%%S"
del /f /q "!_wr_tmp!" >nul 2>&1
if /i "!_wr_state!"=="ACTIVE" goto :wait_ready_ssh_init
if /i "!_wr_state!"=="FAILED" (
    call "!LOG_CMD!" :log_error "Queued Resource %TPU_NAME%-qr entered terminal state=!_wr_state!."
    exit /b 1
)
if /i "!_wr_state!"=="SUSPENDED" (
    call "!LOG_CMD!" :log_error "Queued Resource %TPU_NAME%-qr entered terminal state=!_wr_state!."
    exit /b 1
)
REM wincheck disable=CMD2003
if !ELAPSED! geq !WAIT_TIMEOUT! (
    call "!LOG_CMD!" :log_error "Timed out after !WAIT_TIMEOUT!s waiting for %TPU_NAME% (last state=!_wr_state!)."
    exit /b 1
)
REM wincheck disable=CMD2003
if !WAIT_POLL! gtr 0 (
    set /a "_ping_cnt=!WAIT_POLL! + 1"
    ping -n !_ping_cnt! 127.0.0.1 >nul 2>&1
)
set /a "ELAPSED+=POLL_STEP"
goto :wait_ready_poll

:: ## wait_ready_ssh_init
:: Initializes bounded SSH connectivity verification across all workers.
:wait_ready_ssh_init
set "SSH_TRY=0"
goto :wait_ready_ssh
:: ## wait_ready_ssh
:: Retries SSH true probe across --worker=all up to 5 attempts.
:wait_ready_ssh
REM wincheck disable=CMD2003
if !SSH_TRY! geq 5 (
    call "!LOG_CMD!" :log_error "SSH connectivity check failed across workers on %TPU_NAME%."
    exit /b 1
)
call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --worker=all --command="true" >nul 2>&1
if not errorlevel 1 exit /b 0
set /a "SSH_TRY+=1"
REM wincheck disable=CMD2003
if !WAIT_POLL! gtr 0 ping -n 3 127.0.0.1 >nul 2>&1
goto :wait_ready_ssh

:: ## topology_info
:: Emits deterministic worker count, worker IPs, SKU, runtime, and scheduling JSON for multi-host slices.
:topology_info
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm topology-info <name>"
    exit /b 1
)
set "_topo_tmp=%TEMP%\tpu_topo_%RANDOM%.json"
call gcloud compute tpus tpu-vm describe "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --format=json > "!_topo_tmp!"
if errorlevel 1 (
    del /f /q "!_topo_tmp!" >nul 2>&1
    exit /b 1
)
jq -c --arg def_sku "%TPU_ACCELERATOR_TYPE%" --arg def_rt "!TPU_VERSION!" --arg def_tier "%TPU_SCHEDULING_TYPE%" "([(.networkEndpoints // [])[] | (.ipAddress // .accessConfig.externalIp // \"127.0.0.1\")]) as $ips | (if ($ips | length) == 0 then [\"127.0.0.1\"] else $ips end) as $n | {name: ((.name // \"\") | split(\"/\") | last), worker_count: ($n | length), worker0_internal_ip: $n[0], worker_ips: ($n | join(\",\")), accelerator_type: ((.acceleratorType // $def_sku) | split(\"/\") | last), runtime_version: (.runtimeVersion // $def_rt), scheduling_type: (if .schedulingConfig.spot == true then \"spot\" elif .schedulingConfig.preemptible == true then \"preemptible\" else $def_tier end)}" "!_topo_tmp!"
del /f /q "!_topo_tmp!" >nul 2>&1
exit /b 0

:: ## sync_repo
:: Streams a compressed repository archive to TPU workers when the tree digest changes, skipping idempotently on match.
:sync_repo
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm sync-repo <name> <local_dir> <remote_dir> [--all-workers]"
    exit /b 1
)
shift
shift
set "SYNC_LOCAL="
set "SYNC_REMOTE="
set "SYNC_WORKER_FLAG="
goto :sync_repo_args
:: ## sync_repo_args
:: Parses positional paths and --all-workers for sync-repo.
:sync_repo_args
if "%~1"=="" goto :sync_repo_run
if /i "%~1"=="--all-workers" (
    set "SYNC_WORKER_FLAG=--worker=all"
    shift
    goto :sync_repo_args
)
if "!SYNC_LOCAL!"=="" (
    set "SYNC_LOCAL=%~1"
) else if "!SYNC_REMOTE!"=="" (
    set "SYNC_REMOTE=%~1"
)
shift
goto :sync_repo_args

:: ## sync_repo_run
:: Computes tree digest via remote_sync.cmd, skips transfer when .libscript_sync.sha256 matches, and otherwise streams tar.gz.
:sync_repo_run
if "!SYNC_LOCAL!"=="" exit /b 1
if "!SYNC_REMOTE!"=="" exit /b 1
if not exist "!SYNC_LOCAL!" (
    call "!LOG_CMD!" :log_error "Local repository directory not found: !SYNC_LOCAL!"
    exit /b 1
)
set "SYNC_HASH="
for /f "usebackq delims=" %%H in (`call "!REMOTE_SYNC_CMD!" compute-hash "!SYNC_LOCAL!" 2^>nul`) do set "SYNC_HASH=%%H"
set "_rem_hash_tmp=%TEMP%\tpu_rhash_%RANDOM%.txt"
if not "!SYNC_WORKER_FLAG!"=="" (
    call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% !SYNC_WORKER_FLAG! --command="cat !SYNC_REMOTE!/.libscript_sync.sha256 2>/dev/null || echo MISSING" > "!_rem_hash_tmp!" 2>nul
) else (
    call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command="cat !SYNC_REMOTE!/.libscript_sync.sha256 2>/dev/null || echo MISSING" > "!_rem_hash_tmp!" 2>nul
)
if not "!SYNC_HASH!"=="" if exist "!_rem_hash_tmp!" (
    set "_all_match=1"
    set "_saw_line=0"
    for /f "usebackq delims=" %%L in ("!_rem_hash_tmp!") do (
        set "_saw_line=1"
        if not "%%L"=="!SYNC_HASH!" set "_all_match=0"
    )
    del /f /q "!_rem_hash_tmp!" >nul 2>&1
    if "!_saw_line!"=="1" if "!_all_match!"=="1" (
        call "!LOG_CMD!" :log_info "Remote !SYNC_REMOTE! on %TPU_NAME% already matches tree digest !SYNC_HASH!; skipping transfer."
        exit /b 0
    )
)
del /f /q "!_rem_hash_tmp!" >nul 2>&1

set "_tar_tmp=%TEMP%\libscript_sync_%RANDOM%.tar.gz"
tar -czf "!_tar_tmp!" --exclude=.git --exclude=.venv* --exclude=.tox --exclude=.pytest_cache --exclude=.ruff_cache --exclude=htmlcov --exclude=__pycache__ --exclude=build --exclude=*.pyc -C "!SYNC_LOCAL!" .
if not "!SYNC_WORKER_FLAG!"=="" (
    call gcloud compute tpus tpu-vm scp !SYNC_WORKER_FLAG! "!_tar_tmp!" "%TPU_NAME%:/tmp/libscript_repo_sync.tar.gz" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    set "_scp_rc=!errorlevel!"
) else (
    call gcloud compute tpus tpu-vm scp "!_tar_tmp!" "%TPU_NAME%:/tmp/libscript_repo_sync.tar.gz" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    set "_scp_rc=!errorlevel!"
)
del /f /q "!_tar_tmp!" >nul 2>&1
if not "!_scp_rc!"=="0" exit /b !_scp_rc!

if not "!SYNC_WORKER_FLAG!"=="" (
    call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% !SYNC_WORKER_FLAG! --command="mkdir -p !SYNC_REMOTE! && tar -xzf /tmp/libscript_repo_sync.tar.gz -C !SYNC_REMOTE! && rm -f /tmp/libscript_repo_sync.tar.gz && printf '%%s\n' '!SYNC_HASH!' > !SYNC_REMOTE!/.libscript_sync.sha256"
) else (
    call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command="mkdir -p !SYNC_REMOTE! && tar -xzf /tmp/libscript_repo_sync.tar.gz -C !SYNC_REMOTE! && rm -f /tmp/libscript_repo_sync.tar.gz && printf '%%s\n' '!SYNC_HASH!' > !SYNC_REMOTE!/.libscript_sync.sha256"
)
exit /b !errorlevel!

:: ## arm_ttl
:: Arms an idempotent dead-man's switch auto-shutdown and deletion timer across all TPU workers.
:arm_ttl
if "%TPU_NAME%"=="" exit /b 1
shift
shift
set "TTL_MINUTES=%TFRC_MAX_TTL_MINUTES%"
if "!TTL_MINUTES!"=="" set "TTL_MINUTES=180"
goto :arm_ttl_args
:: ## arm_ttl_args
:: Parses --minutes or --minutes=<int> options for arm-ttl.
:arm_ttl_args
if "%~1"=="" goto :arm_ttl_exec
set "_ta=%~1"
if "!_ta:~0,10!"=="--minutes=" (
    set "TTL_MINUTES=!_ta:~10!"
    shift
    goto :arm_ttl_args
)
if /i "!_ta!"=="--minutes" (
    set "TTL_MINUTES=%~2"
    shift
    shift
    goto :arm_ttl_args
)
shift
goto :arm_ttl_args

:: ## arm_ttl_exec
:: Installs the dead-man's switch timer PID across --worker=all, replacing any prior timer idempotently.
:arm_ttl_exec
set /a "TTL_SECS=TTL_MINUTES * 60"
call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --worker=all --command="if [ -f /tmp/libscript_tfrc_ttl.pid ]; then kill $(cat /tmp/libscript_tfrc_ttl.pid) 2>/dev/null || true; rm -f /tmp/libscript_tfrc_ttl.pid; fi; nohup sh -c 'sleep !TTL_SECS!; gcloud compute tpus queued-resources delete %TPU_NAME%-qr --zone=%TPU_ZONE% --project=%GCP_PROJECT_ID% --force --quiet >/dev/null 2>&1 || true; gcloud compute tpus tpu-vm delete %TPU_NAME% --zone=%TPU_ZONE% --project=%GCP_PROJECT_ID% --quiet >/dev/null 2>&1 || true; /sbin/shutdown -h now >/dev/null 2>&1 || true' >/tmp/libscript_tfrc_ttl.log 2>&1 & echo $! >/tmp/libscript_tfrc_ttl.pid"
exit /b !errorlevel!

:: ## release_locks
:: Releases stale /dev/accel* and /dev/vfio/* locks across all TPU workers and polls until zero processes hold accelerator nodes.
:release_locks
if "%TPU_NAME%"=="" exit /b 1
call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --worker=all --command="if command -v fuser >/dev/null 2>&1; then fuser -k /dev/accel* /dev/vfio/* >/dev/null 2>&1 || true; fi; _tries=0; while [ $_tries -lt 10 ]; do if command -v fuser >/dev/null 2>&1 && fuser /dev/accel* /dev/vfio/* >/dev/null 2>&1; then sleep 1; _tries=$((_tries + 1)); else break; fi; done"
exit /b !errorlevel!

:: ## ssh
:: Connects or executes commands across single or all TPU VM workers without empty flag arguments.
:ssh
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm ssh <name> [--detached] [--forward-port <l>:<r>] [--all-workers] [command]"
    exit /b 1
)
shift
shift
set "DETACHED="
set "FORWARD_PORT="
set "WORKER_FLAG="
set "EXPLICIT_CMD="
goto :ssh_arg_loop
:: ## ssh_arg_loop
:: Parses command-line flags for the TPU ssh subcommand including --key=val forms.
:ssh_arg_loop
if "%~1"=="" goto :ssh_prep
set "_sa=%~1"
if /i "!_sa!"=="--detached" (
    set "DETACHED=true"
    shift
    goto :ssh_arg_loop
)
if "!_sa:~0,15!"=="--forward-port=" (
    set "FORWARD_PORT=!_sa:~15!"
    shift
    goto :ssh_arg_loop
)
if /i "!_sa!"=="--forward-port" (
    set "FORWARD_PORT=%~2"
    shift
    shift
    goto :ssh_arg_loop
)
if /i "!_sa!"=="--all-workers" (
    set "WORKER_FLAG=--worker=all"
    shift
    goto :ssh_arg_loop
)
if "!_sa:~0,9!"=="--worker=" (
    set "WORKER_FLAG=--worker=!_sa:~9!"
    shift
    goto :ssh_arg_loop
)
if /i "!_sa!"=="--worker" (
    set "WORKER_FLAG=--worker=%~2"
    shift
    shift
    goto :ssh_arg_loop
)
if "!_sa:~0,10!"=="--command=" (
    set "EXPLICIT_CMD=!_sa:~10!"
    shift
    goto :ssh_arg_loop
)
if /i "!_sa!"=="--command" (
    set "EXPLICIT_CMD=%~2"
    shift
    shift
    goto :ssh_arg_loop
)
:: wincheck disable=CMD3005

:: ## ssh_prep
:: Builds SSH_FLAGS and collects remaining positional command tokens.
:ssh_prep
set "SSH_FLAGS="
if not "!WORKER_FLAG!"=="" set "SSH_FLAGS=!WORKER_FLAG!"
if not "!FORWARD_PORT!"=="" (
    if "!SSH_FLAGS!"=="" (
        set "SSH_FLAGS=--ssh-flag=-L!FORWARD_PORT!"
    ) else (
        set "SSH_FLAGS=!SSH_FLAGS! --ssh-flag=-L!FORWARD_PORT!"
    )
)
set "REST_ARGS="
if not "!EXPLICIT_CMD!"=="" (
    set "REST_ARGS= !EXPLICIT_CMD!"
    goto :ssh_run
)
:: wincheck disable=CMD3005
:: ## ssh_loop
:: Collects remaining command tokens for remote execution.
:ssh_loop
if "%~1"=="" goto :ssh_run
set "REST_ARGS=!REST_ARGS! %~1"
shift
goto :ssh_loop

:: ## ssh_run
:: Invokes gcloud compute tpus tpu-vm ssh without empty arguments and propagates exit status.
:ssh_run
if "!REST_ARGS!"=="" (
    if "!SSH_FLAGS!"=="" (
        call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    ) else (
        call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% !SSH_FLAGS!
    )
) else (
    if "!DETACHED!"=="true" (
        if "!SSH_FLAGS!"=="" (
            call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command "tmux new-session -d -s ml-session '!REST_ARGS:~1!'"
        ) else (
            call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% !SSH_FLAGS! --command "tmux new-session -d -s ml-session '!REST_ARGS:~1!'"
        )
    ) else (
        if "!SSH_FLAGS!"=="" (
            call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --command "!REST_ARGS:~1!"
        ) else (
            call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% !SSH_FLAGS! --command "!REST_ARGS:~1!"
        )
    )
)
exit /b !errorlevel!

:: ## profile
:: Captures an XLA performance profile from target TPU VM workers.
:profile
if "%TPU_NAME%"=="" exit /b 1
shift
shift
set "PORT=9012"
set "DURATION=1000"
goto :profile_arg_loop
:: ## profile_arg_loop
:: Parses --port and --duration options for profile capture.
:profile_arg_loop
if "%~1"=="" goto :profile_exec
if /i "%~1"=="--port" (
    set "PORT=%~2"
    shift
    shift
    goto :profile_arg_loop
)
if /i "%~1"=="--duration" (
    set "DURATION=%~2"
    shift
    shift
    goto :profile_arg_loop
)
shift
goto :profile_arg_loop

:: ## profile_exec
:: Runs capture_tpu_profile across workers.
:profile_exec
if "%TPU_PROFILE_LOGDIR%"=="" set "TPU_PROFILE_LOGDIR=/tmp/tpu_profile"
call gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --worker=all --command="capture_tpu_profile --tpu=%%HOSTNAME%% --profiler_port=%PORT% --duration_ms=%DURATION% --logdir=%TPU_PROFILE_LOGDIR%"
exit /b !errorlevel!

:: ## scp
:: Copies files between local host and TPU VM workers with --all-workers, --worker, and --recurse support.
:scp
if "%TPU_NAME%"=="" (
    call "!LOG_CMD!" :log_error "Usage: tpu-vm scp <name> <src> <dest> [--all-workers]"
    exit /b 1
)
shift
shift
set "SCP_FLAGS="
set "SRC="
set "DEST="
goto :scp_arg_loop
:: ## scp_arg_loop
:: Parses --all-workers, --worker=*, --recurse, and positional paths for scp.
:scp_arg_loop
if "%~1"=="" goto :scp_run
set "_ca=%~1"
if /i "!_ca!"=="--all-workers" (
    set "SCP_FLAGS=!SCP_FLAGS! --worker=all"
    shift
    goto :scp_arg_loop
)
if "!_ca:~0,9!"=="--worker=" (
    set "SCP_FLAGS=!SCP_FLAGS! --worker=!_ca:~9!"
    shift
    goto :scp_arg_loop
)
if /i "!_ca!"=="--worker" (
    set "SCP_FLAGS=!SCP_FLAGS! --worker=%~2"
    shift
    shift
    goto :scp_arg_loop
)
if /i "!_ca!"=="--recurse" (
    set "SCP_FLAGS=!SCP_FLAGS! --recurse"
    shift
    goto :scp_arg_loop
)
if /i "!_ca!"=="-r" (
    set "SCP_FLAGS=!SCP_FLAGS! --recurse"
    shift
    goto :scp_arg_loop
)
if "!SRC!"=="" (
    set "SRC=!_ca!"
) else if "!DEST!"=="" (
    set "DEST=!_ca!"
) else (
    call "!LOG_CMD!" :log_error "Too many arguments for scp"
    exit /b 1
)
shift
goto :scp_arg_loop

:: ## scp_run
:: Executes gcloud compute tpus tpu-vm scp without empty flag tokens.
:scp_run
if "!SRC!"=="" exit /b 1
if "!DEST!"=="" exit /b 1
if not "!SCP_FLAGS!"=="" if "!SCP_FLAGS:~0,1!"==" " set "SCP_FLAGS=!SCP_FLAGS:~1!"
echo "!DEST!" | findstr ":" >nul
if not errorlevel 1 goto :scp_qualified
echo "!SRC!" | findstr ":" >nul
if not errorlevel 1 goto :scp_qualified
if "!SCP_FLAGS!"=="" (
    call gcloud compute tpus tpu-vm scp "!SRC!" "%TPU_NAME%:!DEST!" --zone="%TPU_ZONE%" %PROJECT_FLAG%
) else (
    call gcloud compute tpus tpu-vm scp !SCP_FLAGS! "!SRC!" "%TPU_NAME%:!DEST!" --zone="%TPU_ZONE%" %PROJECT_FLAG%
)
exit /b !errorlevel!

:: ## scp_qualified
:: Invokes gcloud compute tpus tpu-vm scp when SRC or DEST already contains a node prefix.
:scp_qualified
if "!SCP_FLAGS!"=="" (
    call gcloud compute tpus tpu-vm scp "!SRC!" "!DEST!" --zone="%TPU_ZONE%" %PROJECT_FLAG%
) else (
    call gcloud compute tpus tpu-vm scp !SCP_FLAGS! "!SRC!" "!DEST!" --zone="%TPU_ZONE%" %PROJECT_FLAG%
)
exit /b !errorlevel!

:: ## status
:: Queries status of target TPU VM or Queued Resource nodes.
:status
if "%TPU_NAME%"=="" exit /b 1
if /i "!TPU_USE_QUEUED_RESOURCE!"=="true" (
    call :run_qr_gcloud describe "%TPU_NAME%-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
) else (
    call gcloud compute tpus tpu-vm describe "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
)
exit /b 0
