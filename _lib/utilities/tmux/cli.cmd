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

where tmux >nul 2>nul
if %errorlevel% neq 0 (
    call "%LOG_CMD%" :log_error "tmux not found. Please ensure it is installed and in your PATH."
    exit /b 1
)

set "ACTION=%~1"

if "%ACTION%"=="new-session" goto :new_session
if "%ACTION%"=="attach" goto :attach
if "%ACTION%"=="kill" goto :kill
if "%ACTION%"=="list" goto :list

call "%LOG_CMD%" :log_error "Unknown action: %ACTION%. Supported: new-session, attach, kill, list."
exit /b 1

:new_session
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
shift
shift
set "REST_ARGS="
:loop
if "%~1"=="" goto run
set "REST_ARGS=%REST_ARGS% %~1"
shift
goto loop

:run
tmux has-session -t "%SESSION_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "Session %SESSION_NAME% already exists. Attaching..."
    tmux attach-session -t "%SESSION_NAME%"
) else (
    call "%LOG_CMD%" :log_info "Creating new detached session: %SESSION_NAME%"
    if "%REST_ARGS%"=="" (
        tmux new-session -d -s "%SESSION_NAME%"
    ) else (
        tmux new-session -d -s "%SESSION_NAME%" "%REST_ARGS:~1%"
    )
    call "%LOG_CMD%" :log_info "Started successfully."
)
exit /b 0

:attach
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
call "%LOG_CMD%" :log_info "Attaching to session: %SESSION_NAME%"
tmux attach-session -t "%SESSION_NAME%"
exit /b 0

:kill
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
call "%LOG_CMD%" :log_info "Killing session: %SESSION_NAME%"
tmux kill-session -t "%SESSION_NAME%" >nul 2>&1
exit /b 0

:list
tmux list-sessions
exit /b 0
