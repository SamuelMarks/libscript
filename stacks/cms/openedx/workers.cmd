@echo off
:: # workers.cmd
::
:: ## Overview
:: Background worker and Celery beat scheduler management utility for Open edX on Windows.
:: Manages lms-worker, cms-worker, and celery-beat lifecycle (start, stop, restart, status).
::
:: ## Usage
::   call workers.cmd start
::   call workers.cmd stop
::   call workers.cmd restart
::   call workers.cmd status
::   call workers.cmd help
::
:: ## Exit Codes
::   0 - Success
::   1 - Error

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"

if "%LIBSCRIPT_ROOT_DIR%"=="" (
    for %%i in ("%~dp0..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

if "%OPENEDX_INSTALL_DIR%"=="" (
    if defined LIBSCRIPT_HOME (
        set "OPENEDX_INSTALL_DIR=%LIBSCRIPT_HOME%\openedx"
    ) else (
        set "OPENEDX_INSTALL_DIR=%USERPROFILE%\.libscript\openedx"
    )
)

set "RUN_DIR=%OPENEDX_INSTALL_DIR%\run"
set "LOG_DIR=%OPENEDX_INSTALL_DIR%\logs"
if not exist "%RUN_DIR%" mkdir "%RUN_DIR%"
if not exist "%LOG_DIR%" mkdir "%LOG_DIR%"

set "PYTHON_BIN=%OPENEDX_INSTALL_DIR%\.venv\Scripts\python.exe"
if not exist "%PYTHON_BIN%" set "PYTHON_BIN=python"

set "WORKERS_HELPER=%SCRIPT_DIR%workers_helper.cmd"

set "CMD=%~1"
if "%CMD%"=="" goto show_help
if "%CMD%"=="help" goto show_help
if "%CMD%"=="--help" goto show_help
if "%CMD%"=="-h" goto show_help

if "%CMD%"=="start" goto do_start
if "%CMD%"=="stop" goto do_stop
if "%CMD%"=="restart" goto do_restart
if "%CMD%"=="status" goto do_status

echo [ERROR] Unknown workers command: %CMD% >&2
goto show_help

:: ## do_start
:: Starts Celery background workers and beat scheduler daemon.
:do_start
echo [INFO] Starting Open edX background workers...
call "%WORKERS_HELPER%" start "%RUN_DIR%" "%LOG_DIR%" "%PYTHON_BIN%" "%OPENEDX_INSTALL_DIR%"
exit /b %errorlevel%

:: ## do_stop
:: Stops all active Open edX background worker daemons.
:do_stop
echo [INFO] Stopping Open edX background workers...
call "%WORKERS_HELPER%" stop "%RUN_DIR%"
exit /b %errorlevel%

:: ## do_restart
:: Restarts Open edX background workers.
:do_restart
call :do_stop
call :do_start
exit /b 0

:: ## do_status
:: Checks runtime status and PIDs of background workers.
:do_status
echo ======================================================
echo              Open edX Background Workers Status
echo ======================================================
call "%WORKERS_HELPER%" status "%RUN_DIR%"
echo ======================================================
exit /b 0

:: ## show_help
:: Displays worker management CLI command usage.
:show_help
echo Open edX Worker ^& Scheduler Management CLI (Windows)
echo.
echo Usage:
echo   call workers.cmd start
echo   call workers.cmd stop
echo   call workers.cmd restart
echo   call workers.cmd status
echo   call workers.cmd help
exit /b 0
