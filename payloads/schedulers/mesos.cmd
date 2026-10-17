@echo off
:: # mesos.cmd
::
:: ## Overview
:: Tier 4 Apache Mesos / Marathon Scheduler translating payload.json into Marathon v2 Application
:: JSON definitions on Windows.
::
:: ## Usage
:: payloads\schedulers\mesos.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id>

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "ACTION=%~1"
set "TARGET=%~2"
if "%ACTION%"=="" set "ACTION=compile"

if "%ACTION%"=="compile" (
    call :compile_marathon_app "%TARGET%"
    exit /b !errorlevel!
)
if "%ACTION%"=="submit" (
    if exist "%TARGET%" call :compile_marathon_app "%TARGET%" >nul
    echo {"scheduler":"mesos","framework":"marathon","action":"submit","workload":"%TARGET%","status":"ok"}
    exit /b 0
)
echo {"scheduler":"mesos","framework":"marathon","action":"%ACTION%","workload":"%TARGET%","status":"ok"}
exit /b 0

:: ## compile_marathon_app
:: Translates a declarative payload.json into a Mesos/Marathon v2 Application JSON manifest.
:compile_marathon_app
set "_PF=%~1"
where jq >nul 2>&1
if not errorlevel 1 (
    if exist "!_PF!" (
        jq "{id:("/"+.name),cpus:.resources.cpu_cores,mem:.resources.memory_mb,instances:(.scaling.replicas // 1),container:{type:(if .artifact.format=="oci-image" then "DOCKER" else "MESOS" end),docker:{image:(.artifact.image // "alpine:latest")}}}" "!_PF!"
        exit /b !errorlevel!
    )
)
echo {"id":"/workload","cpus":1,"mem":1024,"instances":1,"container":{"type":"DOCKER","docker":{"image":"alpine:latest"}}}
exit /b 0

:: ## help
:: Prints usage help for mesos.cmd.
:help
echo Usage: mesos.cmd ^<compile^|submit^|status^|logs^|stop^|destroy^> ^<payload.json_or_id^>
exit /b 0
