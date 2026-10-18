@echo off
:: # state_backend.cmd
::
:: ## Overview
:: Handles remote state locking and pushing/pulling for Windows.
::
:: ## Usage
:: Called with `lock_state`, `unlock_state`, `pull_state`, `push_state` to manage concurrency.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

set "STATE_FILE=%STATE_FILE%"
if "%STATE_FILE%"=="" set "STATE_FILE=.libscript_state.json"

set "REMOTE_STATE_URI=%REMOTE_STATE_URI%"

if "%~1"=="lock_state" goto lock_state
if "%~1"=="unlock_state" goto unlock_state
if "%~1"=="pull_state" goto pull_state
if "%~1"=="push_state" goto push_state
goto :eof

:: ## lock_state
:: Performs the lock_state operation and updates component state.
:lock_state
if "%REMOTE_STATE_URI%"=="" (
    if exist "%STATE_FILE%.lock" (
        echo [ERROR] State is locked by another process. ^(%STATE_FILE%.lock exists^) 1>&2
        exit /b 1
    )
    echo %time% > "%STATE_FILE%.lock"
    exit /b 0
)
echo [STATE] Locking remote state at %REMOTE_STATE_URI%...
echo   -^> Mock: Lock acquired for %REMOTE_STATE_URI%
exit /b 0

:: ## unlock_state
:: Performs the unlock_state operation and updates component state.
:unlock_state
if "%REMOTE_STATE_URI%"=="" (
    if exist "%STATE_FILE%.lock" del "%STATE_FILE%.lock"
    exit /b 0
)
echo [STATE] Unlocking remote state at %REMOTE_STATE_URI%...
echo   -^> Mock: Lock released for %REMOTE_STATE_URI%
exit /b 0

:: ## pull_state
:: Performs the pull_state operation and updates component state.
:pull_state
if not "%REMOTE_STATE_URI%"=="" (
    echo [STATE] Pulling state from %REMOTE_STATE_URI%...
)
exit /b 0

:: ## push_state
:: Performs the push_state operation and updates component state.
:push_state
if not "%REMOTE_STATE_URI%"=="" (
    echo [STATE] Pushing state to %REMOTE_STATE_URI%...
)
exit /b 0
