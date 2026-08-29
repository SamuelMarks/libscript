@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for TensorBoard on Windows.
::
:: ## Usage
:: Run `libscript logging/tensorboard [args...]`. Starts the tensorboard service.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

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

where tensorboard >nul 2>nul
if %errorlevel% neq 0 (
    set "TB_PATH=%LIBSCRIPT_ROOT_DIR%\installed\tensorboard\bin\tensorboard.cmd"
    if exist "!TB_PATH!" (
        set "PATH=%LIBSCRIPT_ROOT_DIR%\installed\tensorboard\bin;%PATH%"
    ) else (
        call "%LOG_CMD%" :log_error "tensorboard not found. Please install the logging/tensorboard component first."
        exit /b 1
    )
)

set "ACTION=%~1"

if "%ACTION%"=="start" goto :start

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%. Supported: start."
exit /b 1

:: ## start
:: Executes start functionality.
:start
set "LOGDIR=%~2"
if "%LOGDIR%"=="" set "LOGDIR=%TEMP%\logs"
set "PORT=%~3"
if "%PORT%"=="" set "PORT=6006"

call "%LOG_CMD%" :log_info "Starting TensorBoard on port %PORT% tracking %LOGDIR%..."
tensorboard --logdir="%LOGDIR%" --port="%PORT%" --host=0.0.0.0
exit /b 0
