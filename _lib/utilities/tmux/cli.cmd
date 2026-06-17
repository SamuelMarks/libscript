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

set "TMUX_CMD="
where psmux >nul 2>nul
if %errorlevel% equ 0 (
    set "TMUX_CMD=psmux"
) else (
    where tmux >nul 2>nul
    if %errorlevel% equ 0 (
        set "TMUX_CMD=tmux"
    )
)

if "!TMUX_CMD!"=="" (
    call "%LOG_CMD%" :log_error "Neither psmux nor tmux found. Please ensure one is installed and in your PATH."
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
!TMUX_CMD! has-session -t "%SESSION_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    call "%LOG_CMD%" :log_info "Session %SESSION_NAME% already exists. Attaching..."
    !TMUX_CMD! attach-session -t "%SESSION_NAME%"
) else (
    call "%LOG_CMD%" :log_info "Creating new detached session: %SESSION_NAME%"
    if "%REST_ARGS%"=="" (
        !TMUX_CMD! new-session -d -s "%SESSION_NAME%"
    ) else (
        !TMUX_CMD! new-session -d -s "%SESSION_NAME%" "%REST_ARGS:~1%"
    )
    call "%LOG_CMD%" :log_info "Started successfully."
)
exit /b 0

:attach
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
call "%LOG_CMD%" :log_info "Attaching to session: %SESSION_NAME%"
!TMUX_CMD! attach-session -t "%SESSION_NAME%"
exit /b 0

:kill
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
call "%LOG_CMD%" :log_info "Killing session: %SESSION_NAME%"
!TMUX_CMD! kill-session -t "%SESSION_NAME%" >nul 2>&1
exit /b 0

:list
!TMUX_CMD! list-sessions
exit /b 0
