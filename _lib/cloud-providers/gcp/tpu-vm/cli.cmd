@echo off
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

if "%TPU_DATA_DISK_TYPE%"=="" set "TPU_DATA_DISK_TYPE=pd-balanced"

if "%ACTION%"=="create" goto :create
if "%ACTION%"=="delete" goto :delete
if "%ACTION%"=="start" goto :start
if "%ACTION%"=="stop" goto :stop
if "%ACTION%"=="ssh" goto :ssh

call "%LOG_CMD%" :log_error "Unknown or missing action: %ACTION%. Supported: create, delete, start, stop, ssh."
exit /b 1

:create
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm create <name>"
    exit /b 1
)

set "DISK_FLAG="
if not "%TPU_DATA_DISK_SIZE%"=="" (
    set "DISK_FLAG=--data-disk=source=projects/%GCP_PROJECT_ID%/zones/%TPU_ZONE%/disks/%TPU_NAME%-data,mode=read-write"
    gcloud compute disks describe "%TPU_NAME%-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
    if errorlevel 1 (
        call "%LOG_CMD%" :log_info "Creating persistent data disk %TPU_NAME%-data (%TPU_DATA_DISK_SIZE%GB, %TPU_DATA_DISK_TYPE%)..."
        gcloud compute disks create "%TPU_NAME%-data" --size="%TPU_DATA_DISK_SIZE%GB" --type="%TPU_DATA_DISK_TYPE%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
    ) else (
        call "%LOG_CMD%" :log_info "Data disk %TPU_NAME%-data already exists."
    )
)

call "%LOG_CMD%" :log_info "Checking if TPU VM %TPU_NAME% exists in zone %TPU_ZONE%..."
gcloud compute tpus tpu-vm describe "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "TPU VM %TPU_NAME% already exists. Skipping creation."
) else (
    call "%LOG_CMD%" :log_info "Creating TPU VM %TPU_NAME% (%TPU_ACCELERATOR_TYPE%) in %TPU_ZONE%..."
    if not "%DISK_FLAG%"=="" (
        gcloud compute tpus tpu-vm create "%TPU_NAME%" --zone="%TPU_ZONE%" --accelerator-type="%TPU_ACCELERATOR_TYPE%" --version="%TPU_VERSION%" %DISK_FLAG% %PROJECT_FLAG%
    ) else (
        gcloud compute tpus tpu-vm create "%TPU_NAME%" --zone="%TPU_ZONE%" --accelerator-type="%TPU_ACCELERATOR_TYPE%" --version="%TPU_VERSION%" %PROJECT_FLAG%
    )
    call "%LOG_CMD%" :log_info "TPU VM %TPU_NAME% created successfully."
)
exit /b 0

:delete
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm delete <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Deleting TPU VM %TPU_NAME% in zone %TPU_ZONE%..."
gcloud compute tpus tpu-vm delete "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet
call "%LOG_CMD%" :log_info "TPU VM %TPU_NAME% deleted."
gcloud compute disks describe "%TPU_NAME%-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "Deleting attached data disk %TPU_NAME%-data..."
    gcloud compute disks delete "%TPU_NAME%-data" --zone="%TPU_ZONE%" %PROJECT_FLAG% --quiet
)
exit /b 0

:start
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm start <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Starting TPU VM %TPU_NAME% in zone %TPU_ZONE%..."
gcloud compute tpus tpu-vm start "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
exit /b 0

:stop
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm stop <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Stopping TPU VM %TPU_NAME% in zone %TPU_ZONE%..."
gcloud compute tpus tpu-vm stop "%TPU_NAME%" --zone="%TPU_ZONE%" %PROJECT_FLAG%
exit /b 0

:ssh
if "%TPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: tpu-vm ssh <name> [--detached] [--forward-port <local>:<remote>] [command]"
    exit /b 1
)
shift
shift
set "DETACHED="
set "FORWARD_PORT="
:arg_loop
if "%~1"=="--detached" (
    set "DETACHED=true"
    shift
    goto :arg_loop
)
if "%~1"=="--forward-port" (
    set "FORWARD_PORT=%~2"
    shift
    shift
    goto :arg_loop
)
set "SSH_FLAGS="
if not "%FORWARD_PORT%"=="" (
    set "SSH_FLAGS=--ssh-flag=-L%FORWARD_PORT%"
    call "%LOG_CMD%" :log_info "Forwarding port %FORWARD_PORT%..."
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
