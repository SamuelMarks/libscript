@echo off
:: # cli.cmd
::
:: ## Overview
:: Windows lifecycle CLI router for the iot-mqtt-edge-pod hybrid RTOS + MQTT topology.
::
:: ## Usage
:: cli.cmd <validate|plan|up|status|down>

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

set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=status"
if /I "!ACTION!"=="validate" (
    jq -e --slurpfile sch "!SCRIPT_DIR!\..\constellation.schema.json" "($sch[0].required - keys) | length == 0" "!SCRIPT_DIR!\topology.json" >nul || exit /b 1
    echo [OK] Verified topology.json conforms to constellation.schema.json
    exit /b 0
)
call "!LIBSCRIPT_ROOT_DIR!\workloads\constellations\engine.cmd" "!ACTION!" "!SCRIPT_DIR!\topology.json"
exit /b !ERRORLEVEL!
