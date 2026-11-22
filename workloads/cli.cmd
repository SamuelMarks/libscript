@echo off
:: # cli.cmd
:: ## Overview
:: Tier 5 (T5) unified workloads CLI router on Windows dispatching declarative scheduler payloads, stateful HA constellations,
:: multi-service web application stacks, local/remote stack deployments, and distributed AI/ML training & serving jobs.
:: ## Usage
:: call workloads\cli.cmd <workload|payload|constellation|stack|app|deploy|deploy-remote|up|down|start|stop|status|train|infer> [args...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "SUBCMD=%~1"
if "!SUBCMD!"=="" goto :show_help
if /i "!SUBCMD!"=="--help" goto :show_help
if /i "!SUBCMD!"=="-h" goto :show_help

if /i "!SUBCMD!"=="workload" goto :do_payload
if /i "!SUBCMD!"=="payload" goto :do_payload
if /i "!SUBCMD!"=="constellation" goto :do_constellation
if /i "!SUBCMD!"=="app" goto :do_app
if /i "!SUBCMD!"=="deploy" goto :do_deploy
if /i "!SUBCMD!"=="deploy-remote" goto :do_deploy_remote
if /i "!SUBCMD!"=="stack" goto :do_stack

for %%S in (start stop status health logs restart up down deprovision-db export-state import-state prepare-storage uninstall-service) do (
    if /i "!SUBCMD!"=="%%S" goto :do_service_verb
)
for %%M in (train infer serve-ml eval-ml benchmark-ml) do (
    if /i "!SUBCMD!"=="%%M" goto :do_ml_verb
)

echo Error: Unknown workloads subcommand '!SUBCMD!'. >&2
exit /b 1

:: ## show_help
:: Displays usage instructions for the T5 workloads router.
:show_help
echo Usage: workloads\cli.cmd ^<workload^|payload^|constellation^|stack^|app^|deploy^|deploy-remote^|up^|down^|start^|stop^|status^|train^|infer^> [args...]
exit /b 0

:: ## do_payload
:: Dispatches scheduler-agnostic payload compilation and lifecycle actions.
:do_payload
call "!LIBSCRIPT_ROOT_DIR!\workloads\engine.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_constellation
:: Dispatches stateful HA service constellation choreography.
:do_constellation
call "!LIBSCRIPT_ROOT_DIR!\workloads\constellations\engine.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_app
:: Dispatches multi-service application stack actions.
:do_app
set "_APP_NAME=%~2"
if exist "!LIBSCRIPT_ROOT_DIR!\workloads\apps\!_APP_NAME!\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\workloads\apps\!_APP_NAME!\cli.cmd" %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
echo Error: Unknown application stack '!_APP_NAME!'. >&2
exit /b 1

:: ## do_deploy
:: Dispatches local/manifest stack deployment.
:do_deploy
call "!LIBSCRIPT_ROOT_DIR!\workloads\services\deploy.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_deploy_remote
:: Dispatches remote SSH/WinRM stack deployment.
:do_deploy_remote
call "!LIBSCRIPT_ROOT_DIR!\workloads\services\deploy-remote.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_stack
:: Dispatches explicit stack subcommands.
:do_stack
call "!LIBSCRIPT_ROOT_DIR!\workloads\services\actions.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_service_verb
:: Dispatches service lifecycle verbs (up, down, start, stop, status, logs).
:do_service_verb
set "CMD=!SUBCMD!"
call "!LIBSCRIPT_ROOT_DIR!\workloads\services\actions.cmd" %*
exit /b !errorlevel!

:: ## do_ml_verb
:: Dispatches AI/ML training, serving, evaluation, and benchmark verbs.
:do_ml_verb
set "CMD=!SUBCMD!"
call "!LIBSCRIPT_ROOT_DIR!\workloads\ai\actions.cmd" %*
exit /b !errorlevel!
