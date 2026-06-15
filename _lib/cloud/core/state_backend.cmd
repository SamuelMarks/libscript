@echo off
setlocal ENABLEDELAYEDEXPANSION

set "STATE_FILE=%STATE_FILE%"
if "%STATE_FILE%"=="" set "STATE_FILE=.libscript_state.json"

set "REMOTE_STATE_URI=%REMOTE_STATE_URI%"

if "%~1"=="lock_state" goto lock_state
if "%~1"=="unlock_state" goto unlock_state
if "%~1"=="pull_state" goto pull_state
if "%~1"=="push_state" goto push_state
goto :eof

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

:unlock_state
if "%REMOTE_STATE_URI%"=="" (
    if exist "%STATE_FILE%.lock" del "%STATE_FILE%.lock"
    exit /b 0
)
echo [STATE] Unlocking remote state at %REMOTE_STATE_URI%...
echo   -^> Mock: Lock released for %REMOTE_STATE_URI%
exit /b 0

:pull_state
if not "%REMOTE_STATE_URI%"=="" (
    echo [STATE] Pulling state from %REMOTE_STATE_URI%...
)
exit /b 0

:push_state
if not "%REMOTE_STATE_URI%"=="" (
    echo [STATE] Pushing state to %REMOTE_STATE_URI%...
)
exit /b 0
