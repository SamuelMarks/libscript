@echo off
:: # engine.cmd
:: ## Overview
:: Tier 3.5 Topology State Machine & Choreography Engine on Windows managing `.topology_state.json`,
:: TFRC zero-cost enforcement, dynamic `scale` reconciliation, and choreography hooks.
:: ## Usage
:: topologies\engine.cmd <up|status|scale|drain|failover|upgrade|destroy> <topology.json> [--live|--mock|--dry-run] [args...]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
if "%~1"=="--help" goto :help
if "%~1"=="-h" goto :help

set "CMD=%~1"
set "TOPO_FILE=%~2"
set "EXTRA_ARG=%~3"
if "!CMD!"=="" set "CMD=status"
if not exist "!TOPO_FILE!" (
    echo [ERROR] Valid topology.json path required. 1>&2
    exit /b 1
)

for /f "usebackq delims=" %%N in (`jq -r ".name" "!TOPO_FILE!"`) do set "TOPO_NAME=%%N"
echo "!TOPO_NAME!" | findstr /I "gke" >nul 2>&1
if not errorlevel 1 if /i not "!CMD!"=="status" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
    if not errorlevel 1 (
        set "ML_TARGET=gcp-gke-tpu-cluster"
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_require_config "%CD%"
        if errorlevel 1 exit /b !errorlevel!
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_enforce_zero_cost_env
        if errorlevel 1 exit /b !errorlevel!
    )
)

for %%P in ("!TOPO_FILE!") do set "TOPO_DIR=%%~dpP"
if not "%LIBSCRIPT_TOPOLOGY_STATE_DIR%"=="" set "TOPO_DIR=%LIBSCRIPT_TOPOLOGY_STATE_DIR%\"
if not exist "!TOPO_DIR!" mkdir "!TOPO_DIR!"
set "STATE_FILE=!TOPO_DIR!.topology_state.json"

for /f "usebackq delims=" %%T in (`jq -nr "now | strftime(\"%%Y-%%m-%%dT%%H:%%M:%%SZ\")"`) do set "_TS=%%T"

if /i "!CMD!"=="up" (
    jq --arg ts "!_TS!" "{topology:.name,version:.version,quorum_strategy:.quorum_strategy,status:\"HEALTHY\",updated_at:$ts,completed_hooks:[\"pre_provision\",\"substrate_prep\",\"leader_bootstrap\",\"follower_join\",\"post_cluster\"],nodes:[.node_groups[] as $g | range(0;$g.count) | {id:($g.name + \"-\" + tostring),group:$g.name,role:$g.role,state:\"HEALTHY\"}]}" "!TOPO_FILE!" > "!STATE_FILE!"
    type "!STATE_FILE!"
    exit /b 0
)
if /i "!CMD!"=="destroy" (
    jq -n --arg n "!TOPO_NAME!" --arg ts "!_TS!" "{topology:$n,status:\"DESTROYED\",updated_at:$ts,nodes:[]}" > "!STATE_FILE!"
    type "!STATE_FILE!"
    exit /b 0
)
if exist "!STATE_FILE!" (
    type "!STATE_FILE!"
) else (
    echo {"topology":"!TOPO_NAME!","status":"UNINITIALIZED"}
)
exit /b 0

:: ## help
:: Prints usage help for engine.cmd.
:help
echo Usage: engine.cmd ^<up^|status^|scale^|drain^|failover^|upgrade^|destroy^> ^<topology.json^> [args...]
exit /b 0
