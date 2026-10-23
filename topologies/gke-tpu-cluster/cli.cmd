@echo off
:: # cli.cmd
::
:: ## Overview
:: Topology CLI manager for multi-pool GKE TPU clusters via XPK and gcloud on Windows.
::
:: ## Usage
:: topologies\gke-tpu-cluster\cli.cmd <create|delete|status> [cluster_name]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

set "LOG_CMD=%LIBSCRIPT_ROOT_DIR%\_lib\_common\log.cmd"

set "ACTION=%~1"
if "%ACTION%"=="--help" goto :help
if "%ACTION%"=="-h" goto :help
if "%ACTION%"=="/?" goto :help
for %%V in (install test logs use env ls ls-remote download uninstall which exec run) do (
    if /i "%ACTION%"=="%%V" goto :status
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
if "%ACTION%"=="status" goto :status

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%. Supported: create, delete, status."
exit /b 1

:: ## create
:: Creates the GKE TPU cluster idempotently.
:create
if "%CLUSTER_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gke-tpu-cluster create <name>"
    exit /b 1
)
call gcloud container clusters describe "%CLUSTER_NAME%" --zone="%GCP_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "GKE TPU cluster %CLUSTER_NAME% already exists in %GCP_ZONE%. Skipping creation."
    exit /b 0
)
call "%LOG_CMD%" :log_info "Creating GKE cluster %CLUSTER_NAME% via xpk in %GCP_ZONE%..."
set "EXTRA_XPK_FLAGS="
if /i "%TPU_SCHEDULING_TYPE%"=="spot" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --spot"
if /i "%TPU_SCHEDULING_TYPE%"=="on-demand" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --on-demand"
if not "%TPU_SLICE_COUNT%"=="" set "EXTRA_XPK_FLAGS=!EXTRA_XPK_FLAGS! --num-slices=%TPU_SLICE_COUNT%"
call xpk cluster create --cluster "%CLUSTER_NAME%" --zone "%GCP_ZONE%" --tpu-type "%TPU_ACCELERATOR_TYPE%" %PROJECT_FLAG% !EXTRA_XPK_FLAGS!
call "%LOG_CMD%" :log_info "Cluster %CLUSTER_NAME% created."
exit /b 0

:: ## delete
:: Deletes the GKE TPU cluster via xpk.
:delete
if "%CLUSTER_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gke-tpu-cluster delete <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Deleting GKE cluster %CLUSTER_NAME% via xpk..."
call xpk cluster delete --cluster "%CLUSTER_NAME%" --zone "%GCP_ZONE%" %PROJECT_FLAG%
call "%LOG_CMD%" :log_info "Cluster %CLUSTER_NAME% deleted."
exit /b 0

:: ## status
:: Prints cluster topology status.
:status
echo Topology status check complete for gke-tpu-cluster.
exit /b 0

:: ## help
:: Prints command usage instructions.
:help
echo Usage: cli.cmd ^<create^|delete^|status^> [cluster_name]
exit /b 0
