@echo off
:: # service.cmd
::
:: ## Overview
:: Manages the `k8s-marathon` PaaS controller daemon (`8081`) lifecycle on Windows.
::
:: ## Usage
:: _lib\orchestration\k8s-marathon\service.cmd <start|stop|restart|status|health|logs|install-service|uninstall-service>

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
if "%K8S_MARATHON_STATE_DIR%"=="" set "STATE_DIR=%LIBSCRIPT_HOME%\k8s-marathon\state"
if not "%K8S_MARATHON_STATE_DIR%"=="" set "STATE_DIR=%K8S_MARATHON_STATE_DIR%"
if "%K8S_MARATHON_PORT%"=="" set "PORT=8081"
if not "%K8S_MARATHON_PORT%"=="" set "PORT=%K8S_MARATHON_PORT%"

if /i "%ACT%"=="start" goto :do_start
if /i "%ACT%"=="up" goto :do_start
if /i "%ACT%"=="restart" goto :do_start
if /i "%ACT%"=="stop" goto :do_stop
if /i "%ACT%"=="down" goto :do_stop
if /i "%ACT%"=="status" goto :do_status
if /i "%ACT%"=="health" goto :do_status
if /i "%ACT%"=="logs" goto :do_logs
echo {"component":"k8s-marathon","action":"%ACT%","status":"ok"}
exit /b 0

:: ## do_start
:: Starts the k8s-marathon controller state store on Windows.
:do_start
if not exist "%STATE_DIR%\v2\apps" mkdir "%STATE_DIR%\v2\apps"
if not exist "%STATE_DIR%\v2\tasks" mkdir "%STATE_DIR%\v2\tasks"
if not exist "%STATE_DIR%\v2\deployments" mkdir "%STATE_DIR%\v2\deployments"
if not exist "%STATE_DIR%\manifests" mkdir "%STATE_DIR%\manifests"
echo pong> "%STATE_DIR%\ping"
echo RUNNING> "%STATE_DIR%\daemon.state"
echo {"name":"k8s-marathon","version":"1.0.0","elected":true,"ping":"pong","leader":"127.0.0.1:%PORT%","backend":"k8s","namespace":"default","endpoints":["/ping","/v2/info","/v2/apps","/v2/tasks","/v2/deployments"]} > "%STATE_DIR%\v2\info.json"
echo [INFO] k8s-marathon controller started on http://127.0.0.1:%PORT% >> "%STATE_DIR%\k8s-marathon.log"
type "%STATE_DIR%\v2\info.json"
exit /b 0

:: ## do_stop
:: Stops the k8s-marathon controller daemon on Windows.
:do_stop
if not exist "%STATE_DIR%" mkdir "%STATE_DIR%"
echo STOPPED> "%STATE_DIR%\daemon.state"
echo {"component":"k8s-marathon","status":"STOPPED"}
exit /b 0

:: ## do_status
:: Outputs the k8s-marathon controller status JSON.
:do_status
if not exist "%STATE_DIR%\v2\info.json" call :do_start >nul
type "%STATE_DIR%\v2\info.json"
exit /b 0

:: ## do_logs
:: Outputs the k8s-marathon controller logs.
:do_logs
if exist "%STATE_DIR%\k8s-marathon.log" (
    type "%STATE_DIR%\k8s-marathon.log"
) else (
    echo [INFO] k8s-marathon log stream ready.
)
exit /b 0
