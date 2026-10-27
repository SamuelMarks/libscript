@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the tmux component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script directly to run the CLI functionality for the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

set "PACKAGE_NAME=tmux"

set "ACTION=%~1"
if "%ACTION%"=="install" goto :delegate
if "%ACTION%"=="test" goto :delegate
if "%ACTION%"=="uninstall" goto :delegate
if "%ACTION%"=="remove" goto :delegate
if "%ACTION%"=="info" goto :delegate
if "%ACTION%"=="env" goto :delegate

set "LOG_CMD=%~dp0..\..\_common\log.cmd"

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
    call "!LOG_CMD!" :log_error "Neither psmux nor tmux found. Please ensure one is installed and in your PATH."
    exit /b 1
)

set "ACTION=%~1"

if "%ACTION%"=="new-session" goto :new_session
if "%ACTION%"=="attach" goto :attach
if "%ACTION%"=="kill" goto :kill
if "%ACTION%"=="list" goto :list

call "!LOG_CMD!" :log_error "Unknown action: %ACTION%. Supported: new-session, attach, kill, list."
exit /b 1

:: ## new_session
:: Performs the new_session operation and updates component state.
:new_session
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
shift
shift
set "REST_ARGS="
:: ## loop
:: Parses command-line arguments and populates configuration variables.
:loop
if "%~1"=="" goto run
set "REST_ARGS=%REST_ARGS% %~1"
shift
goto loop

:: ## run
:: Performs the run operation and updates component state.
:run
!TMUX_CMD! has-session -t "%SESSION_NAME%" >nul 2>&1
if %errorlevel% equ 0 (
    call "!LOG_CMD!" :log_info "Session %SESSION_NAME% already exists. Attaching..."
    !TMUX_CMD! attach-session -t "%SESSION_NAME%"
) else (
    call "!LOG_CMD!" :log_info "Creating new detached session: %SESSION_NAME%"
    if "%REST_ARGS%"=="" (
        !TMUX_CMD! new-session -d -s "%SESSION_NAME%"
    ) else (
        !TMUX_CMD! new-session -d -s "%SESSION_NAME%" "%REST_ARGS:~1%"
    )
    call "!LOG_CMD!" :log_info "Started successfully."
)
exit /b 0

:: ## attach
:: Performs the attach operation and updates component state.
:attach
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
call "!LOG_CMD!" :log_info "Attaching to session: %SESSION_NAME%"
!TMUX_CMD! attach-session -t "%SESSION_NAME%"
exit /b 0

:: ## kill
:: Performs the kill operation and updates component state.
:kill
set "SESSION_NAME=%~2"
if "%SESSION_NAME%"=="" set "SESSION_NAME=ml-session"
call "!LOG_CMD!" :log_info "Killing session: %SESSION_NAME%"
!TMUX_CMD! kill-session -t "%SESSION_NAME%" >nul 2>&1
exit /b 0

:: ## list
:: Performs the list operation and updates component state.
:list
!TMUX_CMD! list-sessions
exit /b 0

:: ## delegate
:: Delegates execution to the shared component_core router.
:delegate
call "%~dp0\..\..\_common\component_core.cmd" %*
exit /b %errorlevel%
