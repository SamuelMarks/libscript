@echo off
:: # cli.cmd
:: ## Overview
:: CLI interface for GCP Filestore instances on Windows.
::
:: ## Usage
:: libscript gcp/filestore [create|delete] <name>
::
:: ## Operations
:: - `create <name>`: Create a Filestore instance.
:: - `delete <name>`: Delete a Filestore instance.

setlocal EnableDelayedExpansion

set "LOG_CMD=%~dp0..\..\..\_common\log.cmd"

set "ACTION=%~1"
set "INSTANCE_NAME=%~2"

if "%FILESTORE_TIER%"=="" set "FILESTORE_TIER=BASIC_HDD"
if "%FILESTORE_CAPACITY_GB%"=="" set "FILESTORE_CAPACITY_GB=1024"
if "%FILESTORE_NETWORK%"=="" set "FILESTORE_NETWORK=default"

set "PROJECT_FLAG="
if not "%GCP_PROJECT_ID%"=="" set "PROJECT_FLAG=--project=%GCP_PROJECT_ID%"

if "%ACTION%"=="create" goto :create
if "%ACTION%"=="delete" goto :delete

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%"
exit /b 1

:: ## create
:: Executes create functionality.
:create
if "%INSTANCE_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: filestore create <name>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Creating GCP Filestore %INSTANCE_NAME% in %FILESTORE_ZONE%..."

set "TAGS_ARG="
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init
    if "!LIBSCRIPT_TAG_ENABLE!"=="true" (
        set "TAGS_ARG=--labels=!LIBSCRIPT_TAG_KEY!=!LIBSCRIPT_TAG_VALUE!"
    )
)

gcloud filestore instances describe "%INSTANCE_NAME%" --zone="%FILESTORE_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "Filestore '%INSTANCE_NAME%' already exists in %FILESTORE_ZONE%."
) else (
    gcloud filestore instances create "%INSTANCE_NAME%" --zone="%FILESTORE_ZONE%" --tier="%FILESTORE_TIER%" --file-share="name=vol1,capacity=%FILESTORE_CAPACITY_GB%GB" --network="name=%FILESTORE_NETWORK%" %PROJECT_FLAG% %TAGS_ARG%
)
exit /b 0

:: ## delete
:: Executes delete functionality.
:delete
if "%INSTANCE_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: filestore delete <name>"
    exit /b 1
)
if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp filestore "%INSTANCE_NAME%" "%FILESTORE_ZONE%"
    if errorlevel 1 exit /b 1
)
call "%LOG_CMD%" :log_info "Deleting GCP Filestore %INSTANCE_NAME% in %FILESTORE_ZONE%..."
gcloud filestore instances describe "%INSTANCE_NAME%" --zone="%FILESTORE_ZONE%" %PROJECT_FLAG% >nul 2>&1
if %errorlevel% equ 0 (
    gcloud filestore instances delete "%INSTANCE_NAME%" --zone="%FILESTORE_ZONE%" --quiet %PROJECT_FLAG%
) else (
    call "%LOG_CMD%" :log_info "Filestore '%INSTANCE_NAME%' already deleted or not found."
)
exit /b 0
