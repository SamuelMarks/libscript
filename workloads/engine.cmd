@echo off
:: # engine.cmd
:: ## Overview
:: Tier 4 Payload Router dispatching compile, submit, status, logs, stop, and destroy to pluggable schedulers on Windows.
:: ## Usage
:: workloads\engine.cmd <compile|submit|status|logs|stop|destroy> <payload.json_or_id> [--scheduler <name>]

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

if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

where jq >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
    )
)

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=compile"
set "TARGET=%~2"
set "SCHEDULER=%LIBSCRIPT_SCHEDULER%"
if "%SCHEDULER%"=="" set "SCHEDULER=kubernetes"
shift
shift
set "_EXTRA_ARGS="
goto :parse_eng_args

:: ## parse_eng_args
:: Parses --scheduler and extra arguments for workloads\engine.cmd.
:parse_eng_args
if "%~1"=="" goto :eng_args_done
set "_ea=%~1"
if /i "!_ea!"=="--scheduler" ( set "SCHEDULER=%~2" & shift & shift & goto :parse_eng_args )
if /i "!_ea:~0,12!"=="--scheduler=" ( set "SCHEDULER=!_ea:~12!" & shift & goto :parse_eng_args )
set "_EXTRA_ARGS=!_EXTRA_ARGS! %1"
shift
goto :parse_eng_args

:: ## eng_args_done
:: Normalizes scheduler alias, verifies driver existence, and dispatches to the target scheduler script.
:eng_args_done
set "_VALID_ACTION=0"
for %%V in (compile submit status logs stop destroy) do (
    if /i "!ACTION!"=="%%V" set "_VALID_ACTION=1"
)
if "!_VALID_ACTION!"=="0" (
    echo [ERROR] Unknown payload action: !ACTION! 1>&2
    exit /b 1
)
if /i "!SCHEDULER!"=="tpu-vm" set "SCHEDULER=tpu_vm"
if /i "!SCHEDULER!"=="gcp-tpu-vm" set "SCHEDULER=tpu_vm"
if /i "!SCHEDULER!"=="gke-xpk" set "SCHEDULER=xpk"
if /i "!SCHEDULER!"=="local" set "SCHEDULER=native"

set "SCHED_SCRIPT=!SCRIPT_DIR!\schedulers\!SCHEDULER!.cmd"
if not exist "!SCHED_SCRIPT!" (
    echo [ERROR] Unknown scheduler driver: !SCHEDULER! 1>&2
    exit /b 1
)

call "!SCHED_SCRIPT!" "!ACTION!" "!TARGET!" !_EXTRA_ARGS!
exit /b %errorlevel%

:: ## help
:: Prints usage help for engine.cmd.
:help
echo Usage: engine.cmd ^<compile^|submit^|status^|logs^|stop^|destroy^> ^<payload.json_or_id^> [--scheduler ^<name^>]
exit /b 0
