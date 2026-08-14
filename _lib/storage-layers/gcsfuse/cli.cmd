@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the gcsfuse component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script directly to run the CLI functionality for the component.

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

:: Ensure gcsfuse is available
where gcsfuse >nul 2>nul
if %errorlevel% neq 0 (
    set "GCSFUSE_PATH=%LIBSCRIPT_ROOT_DIR%\installed\gcsfuse\bin\gcsfuse.exe"
    if exist "!GCSFUSE_PATH!" (
        set "PATH=%LIBSCRIPT_ROOT_DIR%\installed\gcsfuse\bin;%PATH%"
    ) else (
        call "%LOG_CMD%" :log_error "gcsfuse not found. Windows support is limited."
        exit /b 1
    )
)

set "ACTION=%~1"
set "BUCKET_NAME=%~2"
set "MOUNT_POINT=%~3"

if "%ACTION%"=="mount" goto :mount
if "%ACTION%"=="unmount" goto :unmount

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%. Supported: mount, unmount."
exit /b 1

:: ## mount
:: Executes mount functionality.
:mount
if "%BUCKET_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gcsfuse mount <bucket_name> <mount_point>"
    exit /b 1
)
if "%MOUNT_POINT%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gcsfuse mount <bucket_name> <mount_point>"
    exit /b 1
)

:: Strip gs:// prefix
set "B_NAME=%BUCKET_NAME:gs://=%"

if not exist "%MOUNT_POINT%" mkdir "%MOUNT_POINT%"
call "%LOG_CMD%" :log_info "Mounting bucket %B_NAME% to %MOUNT_POINT%... (WARNING: Windows fuse support is limited)"
gcsfuse --implicit-dirs "%B_NAME%" "%MOUNT_POINT%"
exit /b 0

:: ## unmount
:: Executes unmount functionality.
:unmount
if "%BUCKET_NAME%"=="" (
    call "%LOG_CMD%" :log_error "Usage: gcsfuse unmount <mount_point>"
    exit /b 1
)
call "%LOG_CMD%" :log_info "Unmounting %BUCKET_NAME%..."
call "%LOG_CMD%" :log_warn "Fusermount is not available on Windows. Please close the gcsfuse process manually."
exit /b 0
