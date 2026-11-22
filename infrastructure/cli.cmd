@echo off
:: # cli.cmd
:: ## Overview
:: Tier 4 (T4) unified infrastructure & cluster substrate CLI router on Windows dispatching cloud IaaS provisioning,
:: cloud resource operators, image imports, Marketplace publishing, and cluster substrate choreography.
:: ## Usage
:: call infrastructure\cli.cmd <provision|deprovision|cluster|import-image|publish-marketplace|backup|restore> [args...]

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

if /i "!SUBCMD!"=="provision" goto :do_provision
if /i "!SUBCMD!"=="deprovision" goto :do_deprovision
if /i "!SUBCMD!"=="backup" goto :do_backup
if /i "!SUBCMD!"=="export-remote" goto :do_backup
if /i "!SUBCMD!"=="restore" goto :do_restore
if /i "!SUBCMD!"=="import-remote" goto :do_restore
if /i "!SUBCMD!"=="import-image" goto :do_import_image
if /i "!SUBCMD!"=="publish-marketplace" goto :do_publish_marketplace
if /i "!SUBCMD!"=="cluster" goto :do_cluster

if exist "!LIBSCRIPT_ROOT_DIR!\infrastructure\providers\!SUBCMD!\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\infrastructure\providers\!SUBCMD!\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
if exist "!LIBSCRIPT_ROOT_DIR!\infrastructure\resources\!SUBCMD!\cli.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\infrastructure\resources\!SUBCMD!\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)

echo Error: Unknown infrastructure subcommand '!SUBCMD!'. >&2
exit /b 1

:: ## show_help
:: Displays usage instructions for the T4 infrastructure router.
:show_help
echo Usage: infrastructure\cli.cmd ^<provision^|deprovision^|cluster^|import-image^|publish-marketplace^|backup^|restore^> [args...]
exit /b 0

:: ## do_provision
:: Dispatches cloud node/fleet provisioning.
:do_provision
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\cli_actions\provision.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_deprovision
:: Dispatches cloud node/fleet teardown.
:do_deprovision
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\cli_actions\deprovision.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_backup
:: Dispatches remote backup export.
:do_backup
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\cli_actions\backup.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_restore
:: Dispatches remote backup import/restore.
:do_restore
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\cli_actions\restore.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_import_image
:: Dispatches cloud custom image import.
:do_import_image
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\resources\image-import\cli.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_publish_marketplace
:: Dispatches cloud Marketplace offer publishing.
:do_publish_marketplace
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\marketplace\publish.cmd" %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## do_cluster
:: Dispatches T4 cluster substrate choreography (plan, up, status, scale, drain, failover, fence, upgrade, destroy).
:do_cluster
set "_CL_VERB=%~2"
if "!_CL_VERB!"=="" set "_CL_VERB=status"
if /i "!_CL_VERB!"=="plan" (
    call "!LIBSCRIPT_ROOT_DIR!\infrastructure\clusters\engine.cmd" up %3 %4 %5 %6 %7 %8 "--dry-run"
    exit /b !errorlevel!
)
if /i "!_CL_VERB!"=="fence" (
    call "!LIBSCRIPT_ROOT_DIR!\infrastructure\clusters\engine.cmd" failover %3 %4 %5 %6 %7 %8 %9
    exit /b !errorlevel!
)
call "!LIBSCRIPT_ROOT_DIR!\infrastructure\clusters\engine.cmd" "!_CL_VERB!" %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!
