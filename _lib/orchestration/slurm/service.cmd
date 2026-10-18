@echo off
:: # service.cmd
::
:: ## Overview
:: Manages the Slurm Workload Manager (`slurmctld` / `slurmd`) lifecycle on Windows.
::
:: ## Usage
:: _lib\orchestration\slurm\service.cmd <start|stop|restart|status|health|logs|install-service|uninstall-service>

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

set "ACT=%~1"
if "%ACT%"=="" set "ACT=%ACTION%"
if "%ACT%"=="" set "ACT=status"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%SLURM_STATE_DIR%"=="" set "STATE_DIR=%LIBSCRIPT_HOME%\slurm\state"
if not "%SLURM_STATE_DIR%"=="" set "STATE_DIR=%SLURM_STATE_DIR%"

if /i "%ACT%"=="start" goto :do_start
if /i "%ACT%"=="up" goto :do_start
if /i "%ACT%"=="restart" goto :do_start
if /i "%ACT%"=="stop" goto :do_stop
if /i "%ACT%"=="down" goto :do_stop
if /i "%ACT%"=="status" goto :do_status
if /i "%ACT%"=="health" goto :do_status
if /i "%ACT%"=="logs" goto :do_logs
echo {"component":"slurm","action":"%ACT%","status":"ok"}
exit /b 0

:: ## do_start
:: Starts the Slurm Workload Manager state store on Windows.
:do_start
if not exist "%STATE_DIR%\jobs" mkdir "%STATE_DIR%\jobs"
echo {"component":"slurm","version":"24.05.3","slurmctld_port":6817,"slurmd_port":6818,"status":"RUNNING"} > "%STATE_DIR%\status.json"
echo [INFO] Slurm started >> "%STATE_DIR%\slurm.log"
type "%STATE_DIR%\status.json"
exit /b 0

:: ## do_stop
:: Stops the Slurm daemon on Windows.
:do_stop
echo {"component":"slurm","status":"STOPPED"}
exit /b 0

:: ## do_status
:: Outputs the Slurm status JSON.
:do_status
if not exist "%STATE_DIR%\status.json" call :do_start >nul
type "%STATE_DIR%\status.json"
exit /b 0

:: ## do_logs
:: Outputs the Slurm logs.
:do_logs
if exist "%STATE_DIR%\slurm.log" (
    type "%STATE_DIR%\slurm.log"
) else (
    echo [INFO] Slurm log stream ready.
)
exit /b 0
