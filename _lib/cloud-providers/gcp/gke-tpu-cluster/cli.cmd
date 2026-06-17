@echo off
setlocal EnableDelayedExpansion

set "LOG_CMD=%~dp0..\..\..\_common\log.cmd"

:: Ensure xpk is available
where xpk >nul 2>nul
if %errorlevel% neq 0 (
    set "XPK_PATH=%LIBSCRIPT_ROOT_DIR%\installed\xpk\bin\xpk.cmd"
    if exist "!XPK_PATH!" (
        set "PATH=%LIBSCRIPT_ROOT_DIR%\installed\xpk\bin;%PATH%"
    ) else (
        call "%LOG_CMD%" :log_error "xpk not found in PATH. Please install the toolchains/xpk component first."
        exit /b 1
    )
)

set "ACTION=%~1"
if "%ACTION%"=="--help" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)
if "%ACTION%"=="-h" (
    echo Usage: %~nx0 ^<action^> [args...]
    echo See README.md for details.
    exit /b 0
)

if not "%~2"=="" (
    set "CLUSTER_NAME=%~2"
) else (
    set "CLUSTER_NAME=%XPK_CLUSTER_NAME%"
)

if "%GCP_ZONE%"=="" set "GCP_ZONE=us-central2-b"
if "%TPU_ACCELERATOR_TYPE%"=="" set "TPU_ACCELERATOR_TYPE=v4-8"

set "PROJECT_FLAG="
if not "%GCP_PROJECT_ID%"=="" set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

if "%ACTION%"=="create" goto :create
if "%ACTION%"=="delete" goto :delete

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%. Supported: create, delete."
exit /b 1

:create
if "%CLUSTER_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gke-tpu-cluster create <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Creating GKE cluster %CLUSTER_NAME% via xpk in %GCP_ZONE%..."
call xpk cluster create --cluster "%CLUSTER_NAME%" --zone "%GCP_ZONE%" --tpu-type "%TPU_ACCELERATOR_TYPE%" %PROJECT_FLAG%
call "%LOG_CMD%" :log_info "Cluster %CLUSTER_NAME% created."
exit /b 0

:delete
if "%CLUSTER_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gke-tpu-cluster delete <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Deleting GKE cluster %CLUSTER_NAME% via xpk..."
call xpk cluster delete --cluster "%CLUSTER_NAME%" --zone "%GCP_ZONE%" %PROJECT_FLAG%
call "%LOG_CMD%" :log_info "Cluster %CLUSTER_NAME% deleted."
exit /b 0
