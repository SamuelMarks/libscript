@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface for managing GCP Cloud TPU VMs on Windows.
::
:: ## Usage
:: Wraps `gcloud compute tpus tpu-vm` to provision, start, stop, and SSH into TPU VMs.
:: Run `libscript gcp/tpu-vm <action> [args...]`.

setlocal EnableDelayedExpansion

set "LOG_CMD=%~dp0..\..\..\_common\log.cmd"

if "%~1"=="--help" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)

:: Ensure gcloud is available
where gcloud >nul 2>nul
if %errorlevel% neq 0 (
    call "%LOG_CMD%" :log_error "gcloud not found in PATH. Please install the gcp/cli component first."
    exit /b 1
)

set "ACTION=%~1"
set "TPU_NAME=%~2"

if "%TPU_ZONE%"=="" (
    call "%LOG_CMD%" :log_error "TPU_ZONE must be explicitly specified."
    exit /b 1
)

if "%GCP_PROJECT_ID%"=="" (
    call "%LOG_CMD%" :log_error "GCP_PROJECT_ID must be explicitly specified to prevent accidental provisioning."
    exit /b 1
)
set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"
if "%TPU_VERSION%"=="" set "TPU_VERSION=tpu-ubuntu2204-base"
if "%TPU_COUNT%"=="" set "TPU_COUNT=1"

if "%TPU_SCHEDULING_TYPE%"=="" set "TPU_SCHEDULING_TYPE=on-demand"
set "SCHEDULING_FLAG="
if "%TPU_SCHEDULING_TYPE%"=="spot" set "SCHEDULING_FLAG=--spot"
if "%TPU_SCHEDULING_TYPE%"=="preemptible" set "SCHEDULING_FLAG=--preemptible"

if "%TPU_DATA_DISK_TYPE%"=="" set "TPU_DATA_DISK_TYPE=pd-balanced"

if "%ACTION%"=="create" goto :create
if "%ACTION%"=="delete" goto :delete
if "%ACTION%"=="start" goto :start
if "%ACTION%"=="stop" goto :stop
if "%ACTION%"=="ssh" goto :ssh
if "%ACTION%"=="scp" goto :scp
if "%ACTION%"=="profile" goto :profile
if "%ACTION%"=="status" goto :status

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%"
exit /b 1

:create
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm create <name>"
    exit /b 1
)
set "i=1"
:create_loop
if !i! gtr %TPU_COUNT% exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
if %TPU_COUNT% gtr 1 (
    set "INSTANCE_NAME=%TPU_NAME%-!i!"
)

set "DISK_FLAG="
if not "%TPU_DATA_DISK_SIZE%"=="" (
    set "DISK_FLAG=--data-disk=source=projects/%GCP_PROJECT_ID%/zones/%TPU_ZONE%/disks/!INSTANCE_NAME!-data,mode=read-write"
    gcloud compute disks describe "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
    if errorlevel 1 (
        call "%LOG_CMD%" :log_info "Creating persistent data disk !INSTANCE_NAME!-data (%TPU_DATA_DISK_SIZE%GB, %TPU_DATA_DISK_TYPE%)..."
        
        set "TAGS_ARG="
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
            call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init
            if "!LIBSCRIPT_TAG_ENABLE!"=="true" (
                set "TAGS_ARG=--labels=!LIBSCRIPT_TAG_KEY!=!LIBSCRIPT_TAG_VALUE!"
            )
        )
        
        gcloud compute disks create "!INSTANCE_NAME!-data" --size="%TPU_DATA_DISK_SIZE%GB" --type="%TPU_DATA_DISK_TYPE%" --zone="%TPU_ZONE%" %PROJECT_FLAG% !TAGS_ARG!
    ) else (
        call "%LOG_CMD%" :log_info "Data disk !INSTANCE_NAME!-data already exists."
    )
)

set "NETWORK_FLAG="
if not "%TPU_NETWORK%"=="" set "NETWORK_FLAG=--network=%TPU_NETWORK%"
if not "%TPU_SUBNETWORK%"=="" set "NETWORK_FLAG=%NETWORK_FLAG% --subnetwork=%TPU_SUBNETWORK%"

if "%TPU_USE_QUEUED_RESOURCE%"=="true" (
    call "%LOG_CMD%" :log_info "Checking if TPU Queued Resource !INSTANCE_NAME!-qr exists in zone %TPU_ZONE%..."
    gcloud alpha compute tpus queued-resources describe "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
    if errorlevel 1 (
        call "%LOG_CMD%" :log_info "Creating TPU Queued Resource !INSTANCE_NAME!-qr (%TPU_ACCELERATOR_TYPE%) in %TPU_ZONE%..."
        
        set "TAGS_ARG="
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
            call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init
            if "!LIBSCRIPT_TAG_ENABLE!"=="true" (
                set "TAGS_ARG=--labels=!LIBSCRIPT_TAG_KEY!=!LIBSCRIPT_TAG_VALUE!"
            )
        )
        
        gcloud alpha compute tpus queued-resources create "!INSTANCE_NAME!-qr" --node-id="!INSTANCE_NAME!" --zone="%TPU_ZONE%" --accelerator-type="%TPU_ACCELERATOR_TYPE%" --runtime-version="%TPU_VERSION%" %SCHEDULING_FLAG% %DISK_FLAG% %NETWORK_FLAG% %PROJECT_FLAG% !TAGS_ARG!
        if errorlevel 1 (
            call "%LOG_CMD%" :log_error "Queued Resource Provisioning failed. Check TFRC quota availability."
            exit /b 1
        )
        call "%LOG_CMD%" :log_info "TPU Queued Resource !INSTANCE_NAME!-qr submitted successfully."
    ) else (
        call "%LOG_CMD%" :log_info "TPU Queued Resource !INSTANCE_NAME!-qr already exists. Skipping creation."
    )
) else (
    call "%LOG_CMD%" :log_info "Checking if TPU VM !INSTANCE_NAME! exists in zone %TPU_ZONE%..."
    gcloud compute tpus tpu-vm describe "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
    if errorlevel 1 (
        call "%LOG_CMD%" :log_info "Creating TPU VM !INSTANCE_NAME! (%TPU_ACCELERATOR_TYPE%) in %TPU_ZONE%..."
        
        set "TAGS_ARG="
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
            call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init
            if "!LIBSCRIPT_TAG_ENABLE!"=="true" (
                set "TAGS_ARG=--labels=!LIBSCRIPT_TAG_KEY!=!LIBSCRIPT_TAG_VALUE!"
            )
        )
        
        gcloud compute tpus tpu-vm create "!INSTANCE_NAME!" --zone="%TPU_ZONE%" --accelerator-type="%TPU_ACCELERATOR_TYPE%" --version="%TPU_VERSION%" %SCHEDULING_FLAG% %DISK_FLAG% %NETWORK_FLAG% %PROJECT_FLAG% !TAGS_ARG!
        if errorlevel 1 (
            call "%LOG_CMD%" :log_error "Provisioning failed. Check TFRC quota availability."
            exit /b 1
        )
        call "%LOG_CMD%" :log_info "TPU VM !INSTANCE_NAME! created successfully."
    ) else (
        call "%LOG_CMD%" :log_info "TPU VM !INSTANCE_NAME! already exists. Skipping creation."
    )
)

set /a i+=1
goto :create_loop

:delete
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm delete <name> [--all]"
    exit /b 1
)
shift
shift
set "ALL_FLAG="
:del_arg_loop
if "%~1"=="--all" (
    set "ALL_FLAG=true"
    shift
    goto :del_arg_loop
)
set "i=1"
set "LIMIT=%TPU_COUNT%"
if not "%ALL_FLAG%"=="true" set "LIMIT=1"
:del_loop
if !i! gtr !LIMIT! exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
if !LIMIT! gtr 1 (
    if %TPU_COUNT% gtr 1 (
        set "INSTANCE_NAME=%TPU_NAME%-!i!"
    )
)
call "%LOG_CMD%" :log_info "Deleting TPU VM !INSTANCE_NAME! in zone %TPU_ZONE%..."
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp tpu-vm "!INSTANCE_NAME!" "%TPU_ZONE%"
    if not errorlevel 1 (
        gcloud compute tpus tpu-vm delete "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet || rem
    )
) else (
    gcloud compute tpus tpu-vm delete "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet || rem
)

if "%TPU_USE_QUEUED_RESOURCE%"=="true" (
    call "%LOG_CMD%" :log_info "Deleting queued resource !INSTANCE_NAME!-qr..."
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp qr "!INSTANCE_NAME!-qr" "%TPU_ZONE%"
        if not errorlevel 1 (
            gcloud alpha compute tpus queued-resources delete "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet --force || rem
        )
    ) else (
        gcloud alpha compute tpus queued-resources delete "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet --force || rem
    )
)
gcloud compute disks describe "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if not errorlevel 1 (
    call "%LOG_CMD%" :log_info "Deleting attached data disk !INSTANCE_NAME!-data..."
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp volume "!INSTANCE_NAME!-data" "%TPU_ZONE%"
        if not errorlevel 1 (
            gcloud compute disks delete "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet || rem
        )
    ) else (
        gcloud compute disks delete "!INSTANCE_NAME!-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet || rem
    )
)
set /a i+=1
goto :del_loop

:start
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm start <name> [--all]"
    exit /b 1
)
shift
shift
set "ALL_FLAG="
:start_arg_loop
if "%~1"=="--all" (
    set "ALL_FLAG=true"
    shift
    goto :start_arg_loop
)
set "i=1"
set "LIMIT=%TPU_COUNT%"
if not "%ALL_FLAG%"=="true" set "LIMIT=1"
:start_loop
if !i! gtr !LIMIT! exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
if !LIMIT! gtr 1 (
    if %TPU_COUNT% gtr 1 (
        set "INSTANCE_NAME=%TPU_NAME%-!i!"
    )
)
call "%LOG_CMD%" :log_info "Starting TPU VM !INSTANCE_NAME! in zone %TPU_ZONE%..."
gcloud compute tpus tpu-vm start "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
set /a i+=1
goto :start_loop

:stop
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm stop <name> [--all]"
    exit /b 1
)
shift
shift
set "ALL_FLAG="
:stop_arg_loop
if "%~1"=="--all" (
    set "ALL_FLAG=true"
    shift
    goto :stop_arg_loop
)
set "i=1"
set "LIMIT=%TPU_COUNT%"
if not "%ALL_FLAG%"=="true" set "LIMIT=1"
:stop_loop
if !i! gtr !LIMIT! exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
if !LIMIT! gtr 1 (
    if %TPU_COUNT% gtr 1 (
        set "INSTANCE_NAME=%TPU_NAME%-!i!"
    )
)
call "%LOG_CMD%" :log_info "Stopping TPU VM !INSTANCE_NAME! in zone %TPU_ZONE%..."
gcloud compute tpus tpu-vm stop "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
set /a i+=1
goto :stop_loop

:ssh
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm ssh <name> [--detached] [--forward-port <local>:<remote>] [--all-workers] [command]"
    exit /b 1
)
shift
shift
set "DETACHED="
set "FORWARD_PORT="
set "ALL_WORKERS="
:ssh_arg_loop
if "%~1"=="--detached" (
    set "DETACHED=true"
    shift
    goto :ssh_arg_loop
)
if "%~1"=="--forward-port" (
    set "FORWARD_PORT=%~2"
    shift
    shift
    goto :ssh_arg_loop
)
if "%~1"=="--all-workers" (
    set "ALL_WORKERS=true"
    shift
    goto :ssh_arg_loop
)
set "SSH_FLAGS="
if not "%FORWARD_PORT%"=="" (
    set "SSH_FLAGS=--ssh-flag=-L%FORWARD_PORT%"
    call "%LOG_CMD%" :log_info "Forwarding port %FORWARD_PORT%..."
)
if "%ALL_WORKERS%"=="true" (
    set "SSH_FLAGS=%SSH_FLAGS% --worker=all"
)

set "REST_ARGS="
:ssh_loop
if "%~1"=="" goto :ssh_run
set "REST_ARGS=%REST_ARGS% %~1"
shift
goto :ssh_loop
:ssh_run
call "%LOG_CMD%" :log_info "Connecting to TPU VM %TPU_NAME%..."
if "%REST_ARGS%"=="" (
    gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% %SSH_FLAGS%
) else (
    if "%DETACHED%"=="true" (
        call "%LOG_CMD%" :log_info "Running command in detached tmux session 'ml-session'"
        gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% %SSH_FLAGS% --command "tmux new-session -d -s ml-session '%REST_ARGS:~1%'"
    ) else (
        gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% %SSH_FLAGS% --command "%REST_ARGS:~1%"
    )
)
exit /b 0

:profile
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm profile <name> [--port 9012] [--duration 1000]"
    exit /b 1
)
shift
shift
set "PORT=9012"
set "DURATION=1000"
:profile_arg_loop
if "%~1"=="--port" (
    set "PORT=%~2"
    shift
    shift
    goto :profile_arg_loop
)
if "%~1"=="--duration" (
    set "DURATION=%~2"
    shift
    shift
    goto :profile_arg_loop
)

call "%LOG_CMD%" :log_info "Initiating capture_tpu_profile session on %TPU_NAME% in %TPU_ZONE%..."
gcloud compute tpus tpu-vm ssh "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --worker=all --command="capture_tpu_profile --tpu=%%HOSTNAME%% --profiler_port=%PORT% --duration_ms=%DURATION% --logdir=/tmp/tpu_profile"
exit /b 0

:scp
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm scp <name> <src> <dest> [--all-workers]"
    exit /b 1
)
shift
shift
set "ALL_WORKERS="
set "SRC="
set "DEST="
:scp_arg_loop
if "%~1"=="" goto :scp_run
if "%~1"=="--all-workers" (
    set "ALL_WORKERS=true"
    shift
    goto :scp_arg_loop
)
if "%SRC%"=="" (
    set "SRC=%~1"
) else if "%DEST%"=="" (
    set "DEST=%~1"
) else (
    call "%LOG_CMD%" :log_error "Too many arguments for scp"
    exit /b 1
)
shift
goto :scp_arg_loop

:scp_run
if "%SRC%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm scp <name> <src> <dest> [--all-workers]"
    exit /b 1
)
if "%DEST%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm scp <name> <src> <dest> [--all-workers]"
    exit /b 1
)
set "SCP_FLAGS="
if "%ALL_WORKERS%"=="true" (
    set "SCP_FLAGS=--worker=all"
)

call "%LOG_CMD%" :log_info "Copying files for TPU VM %TPU_NAME%..."
echo "%DEST%" | findstr ":" >nul
if not errorlevel 1 (
    gcloud compute tpus tpu-vm scp %SCP_FLAGS% "%SRC%" "%DEST%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    exit /b 0
)
echo "%SRC%" | findstr ":" >nul
if not errorlevel 1 (
    gcloud compute tpus tpu-vm scp %SCP_FLAGS% "%SRC%" "%DEST%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    exit /b 0
)
gcloud compute tpus tpu-vm scp %SCP_FLAGS% "%SRC%" "%TPU_NAME%:%DEST%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
exit /b 0

:status
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm status <name> [--all]"
    exit /b 1
)
shift
shift
set "ALL_FLAG="
:status_arg_loop
if "%~1"=="--all" (
    set "ALL_FLAG=true"
    shift
    goto :status_arg_loop
)
set "i=1"
set "LIMIT=%TPU_COUNT%"
if not "%ALL_FLAG%"=="true" set "LIMIT=1"

:status_loop
if !i! gtr !LIMIT! exit /b 0
set "INSTANCE_NAME=%TPU_NAME%"
if !LIMIT! gtr 1 (
    if %TPU_COUNT% gtr 1 (
        set "INSTANCE_NAME=%TPU_NAME%-!i!"
    )
)
call "%LOG_CMD%" :log_info "Status for TPU VM !INSTANCE_NAME! in zone %TPU_ZONE%..."
if "%TPU_USE_QUEUED_RESOURCE%"=="true" (
    gcloud alpha compute tpus queued-resources describe "!INSTANCE_NAME!-qr" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
) else (
    gcloud compute tpus tpu-vm describe "!INSTANCE_NAME!" --zone="%TPU_ZONE%" %PROJECT_FLAG% || rem
)
set /a i+=1
goto :status_loop
