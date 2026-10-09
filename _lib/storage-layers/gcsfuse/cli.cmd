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
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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
