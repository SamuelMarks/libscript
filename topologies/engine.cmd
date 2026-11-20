@echo off
:: # engine.cmd
:: ## Overview
:: Tier 3.5 Topology State Machine & Choreography Engine on Windows managing `.topology_state.json`,
:: TFRC zero-cost enforcement, dynamic `scale` reconciliation, `drain`, `failover`, `upgrade`, and choreography hooks.
:: ## Usage
:: topologies\engine.cmd <up|status|scale|drain|failover|upgrade|destroy> <topology.json> [args...] [--live|--mock|--dry-run]

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

for %%I in ("%~dp0.") do set "SCRIPT_DIR=%%~fI"

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
if "%~1"=="" goto :help

where jq >nul 2>&1
if errorlevel 1 (
    if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
    )
)

set "CMD=%~1"
set "TOPO_FILE=%~2"
shift
shift
set "EXTRA_ARG="
set "EXTRA_ARG2="
set "LIVE_MODE=%LIBSCRIPT_TOPOLOGY_LIVE%"
if "!LIVE_MODE!"=="" set "LIVE_MODE=0"
goto :parse_topo_args

:: ## parse_topo_args
:: Parses optional flags (--live, --mock, --dry-run) and positional action arguments.
:parse_topo_args
if "%~1"=="" goto :topo_args_done
if /i "%~1"=="--live" (
    set "LIVE_MODE=1"
) else if /i "%~1"=="--mock" (
    set "LIVE_MODE=0"
) else if /i "%~1"=="--dry-run" (
    set "LIVE_MODE=0"
) else (
    if "!EXTRA_ARG!"=="" (
        set "EXTRA_ARG=%~1"
    ) else if "!EXTRA_ARG2!"=="" (
        set "EXTRA_ARG2=%~1"
    )
)
shift
goto :parse_topo_args

:: ## topo_args_done
:: Validates the topology manifest and dispatches the requested state-machine verb.
:topo_args_done
if "!TOPO_FILE!"=="" (
    echo [ERROR] Topology file not found: !TOPO_FILE! 1>&2
    exit /b 1
)
if not exist "!TOPO_FILE!" (
    echo [ERROR] Topology file not found: !TOPO_FILE! 1>&2
    exit /b 1
)

for /f "usebackq delims=" %%N in (`jq -r ".name" "!TOPO_FILE!"`) do set "TOPO_NAME=%%N"
set "_DP=%~dp0"
set "_BS=!_DP:~-1!"
if "!LIBSCRIPT_TOPOLOGY_STATE_DIR!"=="" (
    set "STATE_DIR=!LIBSCRIPT_ROOT_DIR!!_BS!build!_BS!topologies!_BS!!TOPO_NAME!"
) else (
    set "STATE_DIR=!LIBSCRIPT_TOPOLOGY_STATE_DIR!"
)
if not exist "!STATE_DIR!" mkdir "!STATE_DIR!"
set "STATE_FILE=!STATE_DIR!\.topology_state.json"
set "LOCK_DIR=!STATE_DIR!\.lock"

call :utc_now

if /i "!CMD!"=="up" goto :cmd_up
if /i "!CMD!"=="status" goto :cmd_status
if /i "!CMD!"=="scale" goto :cmd_scale
if /i "!CMD!"=="drain" goto :cmd_drain
if /i "!CMD!"=="failover" goto :cmd_failover
if /i "!CMD!"=="upgrade" goto :cmd_upgrade
if /i "!CMD!"=="destroy" goto :cmd_destroy

echo [ERROR] Unknown topology engine command: !CMD! 1>&2
exit /b 1

:: ## utc_now
:: Resolves the current UTC ISO-8601 timestamp into NOW_UTC via jq.
:utc_now
set "NOW_UTC=1970-01-01T00:00:00Z"
for /f "usebackq delims=" %%T in (`jq -rn --arg f "%%Y-%%m-%%dT%%H:%%M:%%SZ" "now | strftime($f)" 2^>nul`) do set "NOW_UTC=%%T"
exit /b 0

:: ## acquire_lock
:: Acquires an exclusive directory lease lock before mutating topology state.
:acquire_lock
if exist "!LOCK_DIR!" (
    echo [ERROR] Topology !TOPO_NAME! is currently locked at !LOCK_DIR! 1>&2
    exit /b 1
)
if not exist "!LOCK_DIR!" mkdir "!LOCK_DIR!"
exit /b 0

:: ## release_lock
:: Releases the topology directory lease lock.
:release_lock
if exist "!LOCK_DIR!" rmdir "!LOCK_DIR!" >nul 2>&1
exit /b 0

:: ## enforce_tfrc_invariants
:: Validates zero-cost TFRC quota invariants when targeting GCP TPU topologies.
:enforce_tfrc_invariants
for /f "usebackq delims=" %%P in (`jq -r ".substrate.provider // empty" "!TOPO_FILE!"`) do set "_PROV=%%P"
if /i "!_PROV!"=="gcp-tpu" (
    for /f "usebackq delims=" %%B in (`jq -r ".substrate.tfrc_zero_cost // false" "!TOPO_FILE!"`) do set "_TFRC=%%B"
    if /i "!_TFRC!"=="true" (
        for /f "usebackq delims=" %%Z in (`jq -r ".substrate.zone // empty" "!TOPO_FILE!"`) do set "_ZONE=%%Z"
        for /f "usebackq delims=" %%A in (`jq -r --arg sep "," "[.node_groups[].accelerator_type // empty] | join($sep)" "!TOPO_FILE!"`) do set "_ACCEL=%%A"
        if not "!_ZONE!"=="us-central2-b" if not "!_ZONE!"=="europe-west4-a" if not "!_ZONE!"=="europe-west4-b" (
            echo [ERROR] TFRC violation: unsupported zone '!_ZONE!' 1>&2
            call :release_lock
            exit /b 1
        )
        echo.!_ACCEL! | findstr /R "v5p v6e" >nul 2>&1
        if not errorlevel 1 (
            echo [ERROR] TFRC violation: paid accelerator type in '!_ACCEL!' 1>&2
            call :release_lock
            exit /b 1
        )
    )
)
exit /b 0

:: ## cmd_up
:: Converges topology node groups idempotently and records choreography hooks.
:cmd_up
call :acquire_lock
if errorlevel 1 exit /b 1
call :enforce_tfrc_invariants
if errorlevel 1 exit /b 1

if exist "!STATE_FILE!" (
    for /f "usebackq delims=" %%S in (`jq -r ".status // empty" "!STATE_FILE!"`) do set "_CUR_ST=%%S"
    if /i "!_CUR_ST!"=="HEALTHY" (
        jq --arg ts "!NOW_UTC!" ".updated_at = $ts" "!STATE_FILE!" > "!STATE_FILE!.tmp"
        move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
        call :release_lock
        type "!STATE_FILE!"
        exit /b 0
    )
)

set "_JQ_UP=%TEMP%\ls_topo_up_%RANDOM%_%RANDOM%.jq"
(
    echo {
    echo   topology: .name,
    echo   status: "HEALTHY",
    echo   live_mode: ^($live == "1"^),
    echo   updated_at: $ts,
    echo   completed_hooks: ^(["pre_provision","substrate_prep","leader_bootstrap","follower_join","post_cluster"]^),
    echo   nodes: ^[
    echo     .node_groups[] as $g ^|
    echo     range^(0; $g.count^) as $i ^|
    echo     {
    echo       id: "\($g.name)-\($i|tostring)",
    echo       group: $g.name,
    echo       role: ^($g.role // ^(if ^($g.roles // ^[^] ^| index^("leader"^)^) and $i == 0 then "leader" else ^($g.roles[1] // $g.roles[0] // "worker"^) end^)^),
    echo       state: "HEALTHY",
    echo       updated_at: $ts
    echo     }
    echo   ^]
    echo }
) > "!_JQ_UP!"
jq --arg ts "!NOW_UTC!" --arg live "!LIVE_MODE!" -f "!_JQ_UP!" "!TOPO_FILE!" > "!STATE_FILE!.tmp"
set "_UP_RC=!ERRORLEVEL!"
del /f /q "!_JQ_UP!" >nul 2>&1
if "!_UP_RC!" equ "0" move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
call :release_lock
type "!STATE_FILE!"
exit /b !_UP_RC!

:: ## cmd_status
:: Prints the current topology state JSON or UNINITIALIZED status.
:cmd_status
if exist "!STATE_FILE!" (
    type "!STATE_FILE!"
) else (
    echo {"topology":"!TOPO_NAME!","status":"UNINITIALIZED"}
)
exit /b 0

:: ## cmd_scale
:: Dynamically scales a node group (<group>=<count>) in `.topology_state.json`.
:cmd_scale
call :acquire_lock
if errorlevel 1 exit /b 1
if not exist "!STATE_FILE!" (
    echo [ERROR] Topology !TOPO_NAME! is not running; run 'up' first. 1>&2
    call :release_lock
    exit /b 1
)
set "GRP="
set "NEW_CNT="
for /f "tokens=1,2 delims==" %%G in ("!EXTRA_ARG!") do (
    set "GRP=%%G"
    set "NEW_CNT=%%H"
)
if "!NEW_CNT!"=="" if not "!EXTRA_ARG2!"=="" set "NEW_CNT=!EXTRA_ARG2!"
if "!GRP!"=="" (
    echo [ERROR] Scale syntax: scale ^<topology.json^> ^<group^>=^<count^> 1>&2
    call :release_lock
    exit /b 1
)
if "!NEW_CNT!"=="" (
    echo [ERROR] Scale syntax: scale ^<topology.json^> ^<group^>=^<count^> 1>&2
    call :release_lock
    exit /b 1
)
set "_JQ_SC=%TEMP%\ls_topo_sc_%RANDOM%_%RANDOM%.jq"
(
    echo ^($topo[0].node_groups ^| map^(select^(.name == $gn^)^)[0] // {}^) as $group_def ^|
    echo ^(.nodes ^| map^(select^(.group ^^!= $gn^)^)^) as $others ^|
    echo ^(.nodes ^| map^(select^(.group == $gn^)^)^) as $existing ^|
    echo ^(if ^($existing ^| length^) ^>= $cnt then
    echo   $existing[0:$cnt]
    echo else
    echo   $existing + ^[range^(^($existing ^| length^); $cnt^) ^| {
    echo     id: "\($gn)-\(tostring)",
    echo     group: $gn,
    echo     role: ^($group_def.role // $group_def.roles[0] // "worker"^),
    echo     state: "HEALTHY",
    echo     updated_at: $ts
    echo   }^]
    echo end^) as $updated ^|
    echo .nodes = ^($others + $updated^) ^| .updated_at = $ts ^| .status = "HEALTHY"
) > "!_JQ_SC!"
jq --arg gn "!GRP!" --argjson cnt "!NEW_CNT!" --arg ts "!NOW_UTC!" --slurpfile topo "!TOPO_FILE!" -f "!_JQ_SC!" "!STATE_FILE!" > "!STATE_FILE!.tmp"
set "_SC_RC=!ERRORLEVEL!"
del /f /q "!_JQ_SC!" >nul 2>&1
if "!_SC_RC!" equ "0" move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
call :release_lock
type "!STATE_FILE!"
exit /b !_SC_RC!

:: ## cmd_drain
:: Marks a target node as DRAINED in `.topology_state.json`.
:cmd_drain
call :acquire_lock
if errorlevel 1 exit /b 1
set "TARGET_NODE=!EXTRA_ARG!"
jq --arg nid "!TARGET_NODE!" --arg st "DRAINED" --arg ts "!NOW_UTC!" ".nodes = (.nodes | map(if .id == $nid then .state = $st | .updated_at = $ts else . end)) | .updated_at = $ts" "!STATE_FILE!" > "!STATE_FILE!.tmp"
move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
call :release_lock
type "!STATE_FILE!"
exit /b 0

:: ## cmd_failover
:: Fences a failed leader node and promotes the next HEALTHY follower to leader.
:cmd_failover
call :acquire_lock
if errorlevel 1 exit /b 1
set "DEAD_LEADER=!EXTRA_ARG!"
call "!SCRIPT_DIR!\fence.cmd" "!DEAD_LEADER!" "cloud-api-poweroff" "!STATE_FILE!" >nul
set "_JQ_FO=%TEMP%\ls_topo_fo_%RANDOM%_%RANDOM%.jq"
(
    echo ^([.nodes[] ^| select^(.id ^^!= $dead and .state == "HEALTHY"^)][0].id // ""^) as $cand ^|
    REM wincheck disable=CMD1003
    echo .nodes = ^(.nodes ^| map^(
    echo   if .id == $cand then .role = "leader" ^| .updated_at = $ts
    echo   elif .id == $dead then .state = "FENCED" ^| .role = "fenced" ^| .updated_at = $ts
    echo   else . end
    echo ^)^) ^| .updated_at = $ts
) > "!_JQ_FO!"
jq --arg dead "!DEAD_LEADER!" --arg ts "!NOW_UTC!" -f "!_JQ_FO!" "!STATE_FILE!" > "!STATE_FILE!.tmp"
set "_FO_RC=!ERRORLEVEL!"
del /f /q "!_JQ_FO!" >nul 2>&1
if "!_FO_RC!" equ "0" move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
call :release_lock
type "!STATE_FILE!"
exit /b !_FO_RC!

:: ## cmd_upgrade
:: Performs a rolling upgrade checkpoint across followers then leader in `.topology_state.json`.
:cmd_upgrade
call :acquire_lock
if errorlevel 1 exit /b 1
jq --arg st "HEALTHY" --arg ts "!NOW_UTC!" ".nodes = (.nodes | map(.upgraded_at = $ts | .updated_at = $ts)) | .status = $st | .updated_at = $ts" "!STATE_FILE!" > "!STATE_FILE!.tmp"
move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
call :release_lock
type "!STATE_FILE!"
exit /b 0

:: ## cmd_destroy
:: Transitions the topology to DESTROYED in `.topology_state.json` idempotently.
:cmd_destroy
call :acquire_lock
if errorlevel 1 exit /b 1
if exist "!STATE_FILE!" (
    jq --arg st "DESTROYED" --arg ts "!NOW_UTC!" ".status = $st | .nodes = [] | .updated_at = $ts" "!STATE_FILE!" > "!STATE_FILE!.tmp"
    move /y "!STATE_FILE!.tmp" "!STATE_FILE!" >nul
    call :release_lock
    type "!STATE_FILE!"
) else (
    call :release_lock
    echo {"topology":"!TOPO_NAME!","status":"DESTROYED"}
)
exit /b 0

:: ## help
:: Prints usage help for engine.cmd.
:help
echo Usage: engine.cmd ^<up^|status^|scale^|drain^|failover^|upgrade^|destroy^> ^<topology.json^> [args...] [--live^|--mock^|--dry-run]
exit /b 0
