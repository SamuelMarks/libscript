@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface for managing GCP GPU virtual machines on Windows.
::
:: ## Usage
:: Wraps `gcloud compute instances` to provision, start, stop, and SSH into GPU VMs.
:: Run `libscript gcp/gpu-vm <action> [args...]`.

setlocal enabledelayedexpansion

set "LOG_CMD=%~dp0..\..\_common\log.cmd"
if not exist "%LOG_CMD%" (
    echo [ERROR] Could not find log.cmd
    exit /b 1
)

set "ACTION=%~1"
set "GPU_NAME=%~2"
set "REST_ARGS="

:: ## parse_args
:: Executes parse_args functionality.
:parse_args
if "%~3"=="" goto :done_parse
set "REST_ARGS=%REST_ARGS% %3"
shift
goto :parse_args
:: ## done_parse
:: Executes done_parse functionality.
:done_parse

if "%GPU_ZONE%"=="" (
    call "%LOG_CMD%" :log_error "GPU_ZONE must be explicitly specified."
    exit /b 1
)

if "%GCP_PROJECT_ID%"=="" (
    call "%LOG_CMD%" :log_error "GCP_PROJECT_ID must be explicitly specified to prevent accidental provisioning."
    exit /b 1
)
set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

if "%GPU_MACHINE_TYPE%"=="" set "GPU_MACHINE_TYPE=n1-standard-4"
if "%GPU_ACCELERATOR%"=="" set "GPU_ACCELERATOR=type=nvidia-tesla-t4,count=1"
if "%GPU_IMAGE_PROJECT%"=="" set "GPU_IMAGE_PROJECT=deeplearning-platform-release"
if "%GPU_IMAGE_FAMILY%"=="" set "GPU_IMAGE_FAMILY=common-cu121-debian-11"

if "%GPU_DATA_DISK_TYPE%"=="" set "GPU_DATA_DISK_TYPE=pd-balanced"

if "%ACTION%"=="create" goto :create
if "%ACTION%"=="delete" goto :delete
if "%ACTION%"=="start" goto :start
if "%ACTION%"=="stop" goto :stop
if "%ACTION%"=="ssh" goto :ssh

call "%LOG_CMD%" :log_error "Unknown or missing action: %ACTION%. Supported: create, delete, start, stop, ssh."
exit /b 1

:: ## create
:: Executes create functionality.
:create
if "%GPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gpu-vm create <name>"
    exit /b 1
)
set "DISK_FLAG="
if not "%GPU_DATA_DISK_SIZE%"=="" (
    set "DISK_FLAG=--disk=name=%GPU_NAME%-data,mode=rw,boot=no,device-name=%GPU_NAME%-data"
    gcloud compute disks describe "%GPU_NAME%-data" --zone="%GPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
    if errorlevel 1 (
        call "%LOG_CMD%" :log_info "Creating persistent data disk %GPU_NAME%-data (%GPU_DATA_DISK_SIZE%GB, %GPU_DATA_DISK_TYPE%)..."
        
        set "TAGS_ARG="
        if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
            call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init
            if "!LIBSCRIPT_TAG_ENABLE!"=="true" (
                set "TAGS_ARG=--labels=!LIBSCRIPT_TAG_KEY!=!LIBSCRIPT_TAG_VALUE!"
            )
        )
        
        gcloud compute disks create "%GPU_NAME%-data" --size="%GPU_DATA_DISK_SIZE%GB" --type="%GPU_DATA_DISK_TYPE%" --zone="%GPU_ZONE%" %PROJECT_FLAG% !TAGS_ARG!
    ) else (
        call "%LOG_CMD%" :log_info "Data disk %GPU_NAME%-data already exists."
    )
)

call "%LOG_CMD%" :log_info "Checking if GPU VM %GPU_NAME% exists in zone %GPU_ZONE%..."
gcloud compute instances describe "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "GPU VM %GPU_NAME% already exists. Skipping creation."
) else (
    call "%LOG_CMD%" :log_info "Creating GPU VM %GPU_NAME% (%GPU_MACHINE_TYPE%, %GPU_ACCELERATOR%) in %GPU_ZONE%..."
    
    set "TAGS_ARG="
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init
        if "!LIBSCRIPT_TAG_ENABLE!"=="true" (
            set "TAGS_ARG=--labels=!LIBSCRIPT_TAG_KEY!=!LIBSCRIPT_TAG_VALUE!"
        )
    )
    
    gcloud compute instances create "%GPU_NAME%" --zone="%GPU_ZONE%" --machine-type="%GPU_MACHINE_TYPE%" --accelerator="%GPU_ACCELERATOR%" --image-project="%GPU_IMAGE_PROJECT%" --image-family="%GPU_IMAGE_FAMILY%" --maintenance-policy=TERMINATE %DISK_FLAG% %PROJECT_FLAG% !TAGS_ARG!
    call "%LOG_CMD%" :log_info "GPU VM %GPU_NAME% created successfully."
)
exit /b 0

:: ## delete
:: Executes delete functionality.
:delete
if "%GPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gpu-vm delete <name>"
    exit /b 1
)
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp gpu-vm "%GPU_NAME%" "%GPU_ZONE%"
    if errorlevel 1 exit /b 1
)
call "%LOG_CMD%" :log_info "Deleting GPU VM %GPU_NAME% in zone %GPU_ZONE%..."
gcloud compute instances describe "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    gcloud compute instances delete "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG% --quiet
) else (
    call "%LOG_CMD%" :log_info "GPU VM %GPU_NAME% already deleted or not found."
)
call "%LOG_CMD%" :log_info "GPU VM %GPU_NAME% deleted."
gcloud compute disks describe "%GPU_NAME%-data" --zone="%GPU_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp volume "%GPU_NAME%-data" "%GPU_ZONE%"
        if errorlevel 1 exit /b 1
    )
    call "%LOG_CMD%" :log_info "Deleting attached data disk %GPU_NAME%-data..."
    gcloud compute disks delete "%GPU_NAME%-data" --zone="%GPU_ZONE%" %PROJECT_FLAG% --quiet
)
exit /b 0

:: ## start
:: Executes start functionality.
:start
if "%GPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gpu-vm start <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Starting GPU VM %GPU_NAME% in zone %GPU_ZONE%..."
gcloud compute instances start "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG%
exit /b 0

:: ## stop
:: Executes stop functionality.
:stop
if "%GPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gpu-vm stop <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Stopping GPU VM %GPU_NAME% in zone %GPU_ZONE%..."
gcloud compute instances stop "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG%
exit /b 0

:: ## ssh
:: Executes ssh functionality.
:ssh
if "%GPU_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gpu-vm ssh <name> [--detached] [--forward-port <local>:<remote>] [command]"
    exit /b 1
)
shift
shift
set "DETACHED="
set "FORWARD_PORT="
:: ## arg_loop
:: Executes arg_loop functionality.
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
:: ## gather_ssh_args
:: Executes gather_ssh_args functionality.
:gather_ssh_args
if "%~1"=="" goto :done_ssh_args
set "REST_ARGS=%REST_ARGS% %1"
shift
goto :gather_ssh_args
:: ## done_ssh_args
:: Executes done_ssh_args functionality.
:done_ssh_args

if "%REST_ARGS%"=="" (
    gcloud compute ssh "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG% %SSH_FLAGS%
) else (
    if "%DETACHED%"=="true" (
        call "%LOG_CMD%" :log_info "Running command in detached tmux session 'ml-session'"
        gcloud compute ssh "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG% %SSH_FLAGS% --command "tmux new-session -d -s ml-session '%REST_ARGS:~1%'"
    ) else (
        gcloud compute ssh "%GPU_NAME%" --zone="%GPU_ZONE%" %PROJECT_FLAG% %SSH_FLAGS% --command "%REST_ARGS:~1%"
    )
)
exit /b 0