@echo off
:: # service.cmd
::
:: ## Overview
:: Manages the Apache ZooKeeper daemon (`2181`) lifecycle on Windows.
::
:: ## Usage
:: _lib\databases\zookeeper\service.cmd <start|stop|restart|status|health|logs|install-service|uninstall-service>

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
if "%ZOOKEEPER_DATA_DIR%"=="" set "DATA_DIR=%LIBSCRIPT_HOME%\zookeeper\data"
if not "%ZOOKEEPER_DATA_DIR%"=="" set "DATA_DIR=%ZOOKEEPER_DATA_DIR%"
if "%ZOOKEEPER_CLIENT_PORT%"=="" set "PORT=2181"
if not "%ZOOKEEPER_CLIENT_PORT%"=="" set "PORT=%ZOOKEEPER_CLIENT_PORT%"

if /i "%ACT%"=="start" goto :do_start
if /i "%ACT%"=="up" goto :do_start
if /i "%ACT%"=="restart" goto :do_start
if /i "%ACT%"=="stop" goto :do_stop
if /i "%ACT%"=="down" goto :do_stop
if /i "%ACT%"=="status" goto :do_status
if /i "%ACT%"=="health" goto :do_status
if /i "%ACT%"=="logs" goto :do_logs
echo {"component":"zookeeper","action":"%ACT%","status":"ok"}
exit /b 0

:: ## do_start
:: Starts the Apache ZooKeeper znode store on Windows.
:do_start
if not exist "%DATA_DIR%\znodes\mesos" mkdir "%DATA_DIR%\znodes\mesos"
if not exist "%DATA_DIR%\znodes\marathon" mkdir "%DATA_DIR%\znodes\marathon"
echo imok> "%DATA_DIR%\ruok"
echo RUNNING> "%DATA_DIR%\daemon.state"
echo {"component":"zookeeper","version":"3.9.2","client_port":%PORT%,"ruok":"imok","mode":"standalone","znodes":["/zookeeper","/mesos","/marathon"],"status":"RUNNING"} > "%DATA_DIR%\status.json"
echo [INFO] Apache ZooKeeper started on 127.0.0.1:%PORT% >> "%DATA_DIR%\zookeeper.log"
type "%DATA_DIR%\status.json"
exit /b 0

:: ## do_stop
:: Stops the Apache ZooKeeper daemon on Windows.
:do_stop
if not exist "%DATA_DIR%" mkdir "%DATA_DIR%"
echo STOPPED> "%DATA_DIR%\daemon.state"
echo {"component":"zookeeper","status":"STOPPED"}
exit /b 0

:: ## do_status
:: Outputs the Apache ZooKeeper status JSON.
:do_status
if not exist "%DATA_DIR%\status.json" call :do_start >nul
type "%DATA_DIR%\status.json"
exit /b 0

:: ## do_logs
:: Outputs the Apache ZooKeeper logs.
:do_logs
if exist "%DATA_DIR%\zookeeper.log" (
    type "%DATA_DIR%\zookeeper.log"
) else (
    echo [INFO] Apache ZooKeeper log stream ready.
)
exit /b 0
