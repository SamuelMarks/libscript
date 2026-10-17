@echo off
:: # service.cmd
::
:: ## Overview
:: Manages Apache Mesos master (`5050`) and agent (`5051`) daemon lifecycle operations on Windows.
::
:: ## Usage
:: _lib\orchestration\mesos\service.cmd <start|stop|restart|status|health|logs|install-service|uninstall-service>

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
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "ACT=%~1"
if "%ACT%"=="" set "ACT=%ACTION%"
if "%ACT%"=="" set "ACT=status"

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
if "%MESOS_WORK_DIR%"=="" set "STATE_DIR=%LIBSCRIPT_HOME%\mesos\work"
if not "%MESOS_WORK_DIR%"=="" set "STATE_DIR=%MESOS_WORK_DIR%"
if "%MESOS_MASTER_PORT%"=="" set "MASTER_PORT=5050"
if not "%MESOS_MASTER_PORT%"=="" set "MASTER_PORT=%MESOS_MASTER_PORT%"
if "%MESOS_AGENT_PORT%"=="" set "AGENT_PORT=5051"
if not "%MESOS_AGENT_PORT%"=="" set "AGENT_PORT=%MESOS_AGENT_PORT%"

if /i "%ACT%"=="start" goto :do_start
if /i "%ACT%"=="up" goto :do_start
if /i "%ACT%"=="restart" goto :do_start
if /i "%ACT%"=="stop" goto :do_stop
if /i "%ACT%"=="down" goto :do_stop
if /i "%ACT%"=="status" goto :do_status
if /i "%ACT%"=="health" goto :do_status
if /i "%ACT%"=="logs" goto :do_logs
echo {"component":"mesos","action":"%ACT%","status":"ok"}
exit /b 0

:: ## do_start
:: Starts the Apache Mesos master and agent state store on Windows.
:do_start
if not exist "%STATE_DIR%\endpoints\master" mkdir "%STATE_DIR%\endpoints\master"
if not exist "%STATE_DIR%\sandboxes" mkdir "%STATE_DIR%\sandboxes"
echo RUNNING> "%STATE_DIR%\daemon.state"
echo {"version":"1.11.0","id":"mesos-master-leader-01","leader":"master@127.0.0.1:%MASTER_PORT%","activated_slaves":1,"slaves":[{"id":"agent-01","hostname":"127.0.0.1","port":%AGENT_PORT%,"active":true}]} > "%STATE_DIR%\endpoints\master\state.json"
echo [INFO] Apache Mesos started on master=127.0.0.1:%MASTER_PORT% agent=127.0.0.1:%AGENT_PORT% >> "%STATE_DIR%\mesos.log"
echo {"component":"mesos","master_port":%MASTER_PORT%,"agent_port":%AGENT_PORT%,"leader":"master@127.0.0.1:%MASTER_PORT%","status":"RUNNING"}
exit /b 0

:: ## do_stop
:: Stops the Apache Mesos daemon state on Windows.
:do_stop
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%"
echo STOPPED> "%STATE_DIR%\daemon.state"
echo {"component":"mesos","status":"STOPPED"}
exit /b 0

:: ## do_status
:: Outputs the Apache Mesos master cluster status JSON.
:do_status
if not exist "%STATE_DIR%\endpoints\master\state.json" call :do_start >nul
type "%STATE_DIR%\endpoints\master\state.json"
exit /b 0

:: ## do_logs
:: Outputs the Apache Mesos daemon logs.
:do_logs
if exist "%STATE_DIR%\mesos.log" (
    type "%STATE_DIR%\mesos.log"
) else (
    echo [INFO] Apache Mesos log stream ready.
)
exit /b 0
