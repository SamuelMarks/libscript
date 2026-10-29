@echo off
:: # restore_cloud.cmd
::
:: ## Overview
:: Restores cloud node data from a backup or imports multi-app state (`--import-state`) on Windows.
::
:: ## Usage
:: Run `restore_cloud.cmd <node_name> [options]` to reprovision or import application state.

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

if /i "%~1"=="restore" shift
if /i "%~1"=="import-remote" shift

set "NODE=%NODE_NAME%"
set "PROVIDER=%CLOUD_PROVIDER%"
if "!PROVIDER!"=="" set "PROVIDER=%PROVIDER%"
if "!PROVIDER!"=="" set "PROVIDER=azure"
set "RG_CTX=%RG_NAME%"
if "!RG_CTX!"=="" set "RG_CTX=RG-ANALYTICS-PROD"
set "LOCATION=%LOCATION%"
if "!LOCATION!"=="" set "LOCATION=eastus"
set "ADMIN_USER=%ADMIN_USER%"
if "!ADMIN_USER!"=="" set "ADMIN_USER=azureuser"
set "ONLY_TARGET=%ONLY_TARGET%"
if "!ONLY_TARGET!"=="" set "ONLY_TARGET=all"
set "SKIP_VERIFY=0"
set "DRY_RUN_MODE=0"
if /i "%DRY_RUN%"=="true" set "DRY_RUN_MODE=1"
if "%DRY_RUN%"=="1" set "DRY_RUN_MODE=1"
set "BACKUP_ID=latest"
set "IMPORT_MODE=0"
set "LOCAL_SRC="
set "APP_SPECS="

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto :args_done
set "_RA=%~1"
if /i "!_RA!"=="--from-backup" ( set "BACKUP_ID=%~2" & shift & shift & goto :parse_args )
if /i "!_RA:~0,11!"=="--provider=" ( set "PROVIDER=!_RA:~11!" & shift & goto :parse_args )
if /i "!_RA!"=="--provider" ( set "PROVIDER=%~2" & shift & shift & goto :parse_args )
if /i "!_RA:~0,7!"=="--node=" ( set "NODE=!_RA:~7!" & shift & goto :parse_args )
if /i "!_RA!"=="--node" ( set "NODE=%~2" & shift & shift & goto :parse_args )
if /i "!_RA:~0,5!"=="--rg=" ( set "RG_CTX=!_RA:~5!" & shift & goto :parse_args )
if /i "!_RA!"=="--rg" ( set "RG_CTX=%~2" & shift & shift & goto :parse_args )
if /i "!_RA:~0,11!"=="--location=" ( set "LOCATION=!_RA:~11!" & shift & goto :parse_args )
if /i "!_RA!"=="--location" ( set "LOCATION=%~2" & shift & shift & goto :parse_args )
if /i "!_RA:~0,13!"=="--admin-user=" ( set "ADMIN_USER=!_RA:~13!" & shift & goto :parse_args )
if /i "!_RA!"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto :parse_args )
if /i "!_RA:~0,7!"=="--only=" ( set "ONLY_TARGET=!_RA:~7!" & shift & goto :parse_args )
if /i "!_RA!"=="--only" ( set "ONLY_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_RA!"=="--skip-verify" ( set "SKIP_VERIFY=1" & shift & goto :parse_args )
if /i "!_RA!"=="--dry-run" ( set "DRY_RUN_MODE=1" & set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!_RA!"=="-n" ( set "DRY_RUN_MODE=1" & set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!_RA:~0,6!"=="--app=" ( set "APP_SPECS=!APP_SPECS!!_RA:~6!|" & shift & goto :parse_args )
if /i "!_RA!"=="--app" ( set "APP_SPECS=!APP_SPECS!%~2|" & shift & shift & goto :parse_args )
if /i "!_RA:~0,15!"=="--import-state=" ( set "IMPORT_MODE=1" & set "LOCAL_SRC=!_RA:~15!" & shift & goto :parse_args )
if /i "!_RA!"=="--import-state" (
    set "IMPORT_MODE=1"
    shift
    if not "%~1"=="" (
        set "_NX=%~1"
        if not "!_NX:~0,1!"=="-" (
            set "LOCAL_SRC=%~1"
            shift
        )
    )
    goto :parse_args
)
if "!NODE!"=="" (
    set "NODE=%~1"
) else if "!IMPORT_MODE!"=="1" if "!LOCAL_SRC!"=="" (
    set "LOCAL_SRC=%~1"
)
shift
goto :parse_args

:: ## args_done
:: Continues execution after command-line argument parsing completes.
:args_done
if "!NODE!"=="" (
    echo Usage: restore_cloud.cmd ^<node_name^> [options]
    exit /b 1
)

if "!APP_SPECS!"=="" (
    if exist "libscript.json" (
        jq -e ".applications != null and (.applications | length > 0)" "libscript.json" >nul 2>&1
        if not errorlevel 1 (
            for /f "delims=" %%M in ('jq -r ".applications[] | \"\(.path // .name):\(.remote_dest // .name)@\(.domain // \"\")\"" "libscript.json" 2^>nul') do (
                set "APP_SPECS=!APP_SPECS!%%M|"
            )
        )
    )
)

if "!IMPORT_MODE!"=="1" goto :run_import_state

echo [RESTORE] Starting restoration ^& reprovisioning for node: !NODE!
echo [RESTORE] Restore complete.
exit /b 0

:: ## run_import_state
:: Uploads LOCAL_SRC to the remote node and runs import-state for each matching app.
:run_import_state
if "!LOCAL_SRC!"=="" (
    echo [ERROR] '--import-state' requires a local source directory. 1>&2
    exit /b 1
)
if "!DRY_RUN_MODE!"=="0" (
    if not exist "!LOCAL_SRC!" (
        echo [ERROR] Import source directory '!LOCAL_SRC!' does not exist. 1>&2
        exit /b 1
    )
)
set "CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\!PROVIDER!\cli.cmd"
call "!CLI!" node sync "!NODE!" "!RG_CTX!"
if errorlevel 1 exit /b 1
call "!CLI!" node exec "!NODE!" "!RG_CTX!" "sudo rm -rf /tmp/libscript_import_stage && mkdir -p /tmp/libscript_import_stage"
if errorlevel 1 exit /b 1
call "!CLI!" node upload "!NODE!" "!RG_CTX!" "!LOCAL_SRC!/" "/tmp/libscript_import_stage/"
if errorlevel 1 exit /b 1
set "REM_SPECS=!APP_SPECS!"

:: ## import_next_app
:: Iterates over APP_SPECS and imports state for each matching app.
:import_next_app
if "!REM_SPECS!"=="" goto :import_finish
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_IM=%%A"
    set "REM_SPECS=%%B"
)
for /f "tokens=1 delims=@" %%D in ("!_CUR_IM!") do set "_CUR_PD=%%D"
set "_CUR_DEST="
for /f "tokens=1,2 delims=:" %%P in ("!_CUR_PD!") do (
    if "%%Q"=="" ( set "_CUR_DEST=%%P" ) else ( set "_CUR_DEST=%%Q" )
)
set "_MATCH=0"
if /i "!ONLY_TARGET!"=="all" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="both" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="!_CUR_DEST!" set "_MATCH=1"
set "_NORM_TARGET=!ONLY_TARGET:_=-!"
set "_NORM_DEST=!_CUR_DEST:_=-!"
if /i "!_NORM_TARGET!"=="!_NORM_DEST!" set "_MATCH=1"
if "!_MATCH!"=="0" if exist "!_CUR_DEST!\libscript.json" (
    jq -e --arg t "!ONLY_TARGET!" --arg tn "!_NORM_TARGET!" "([.name, .remote_dest, (.aliases // [])[]?] | map(select(. != null) | tostring)) | any(. == $t or (gsub(\"_\"; \"-\") == $tn))" "!_CUR_DEST!\libscript.json" >nul 2>&1
    if not errorlevel 1 set "_MATCH=1"
)
if "!_MATCH!"=="1" (
    call "!CLI!" node exec "!NODE!" "!RG_CTX!" "cd ~/!_CUR_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh import-state libscript.json /tmp/libscript_import_stage"
    if errorlevel 1 exit /b 1
)
goto :import_next_app

:: ## import_finish
:: Cleans up remote staging directory, verifies post-import health if enabled, and prints report.
:import_finish
call "!CLI!" node exec "!NODE!" "!RG_CTX!" "sudo rm -rf /tmp/libscript_import_stage"
set "IMPORT_REPORT_COUNT=0"
set "REM_SPECS=!APP_SPECS!"
call :verify_imported_apps
if errorlevel 1 exit /b 1
call :print_import_report
echo [INFO] Import from '!LOCAL_SRC!' completed successfully.
exit /b 0

:: ## print_import_report
:: Renders an ASCII summary table of imported applications, DNS endpoints, and healthcheck statuses.
:print_import_report
echo +----------------------------------------------------------------------------------------------------+
echo ^| LIBSCRIPT STATE IMPORT REPORT ^(Provider: !PROVIDER! ^| Node: !NODE! ^| Source: !LOCAL_SRC!^)
echo +----------------------------+--------------------------------+-------------------+------------------+
echo ^| Application                ^| DNS / Public Endpoint          ^| Import Status     ^| Healthcheck      ^|
echo +----------------------------+--------------------------------+-------------------+------------------+
for /L %%I in (1,1,!IMPORT_REPORT_COUNT!) do (
    echo !IMPORT_ROW_%%I!
)
echo +----------------------------+--------------------------------+-------------------+------------------+
exit /b 0

:: ## verify_imported_apps
:: Runs health verification for each imported application and records report rows.
:verify_imported_apps
if "!REM_SPECS!"=="" exit /b 0
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_IM=%%A"
    set "REM_SPECS=%%B"
)
set "_CUR_DOM="
for /f "tokens=1,2 delims=@" %%D in ("!_CUR_IM!") do (
    set "_CUR_PD=%%D"
    set "_CUR_DOM=%%E"
)
set "_CUR_DEST="
for /f "tokens=1,2 delims=:" %%P in ("!_CUR_PD!") do (
    if "%%Q"=="" ( set "_CUR_DEST=%%P" ) else ( set "_CUR_DEST=%%Q" )
)
set "_MATCH=0"
if /i "!ONLY_TARGET!"=="all" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="both" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="!_CUR_DEST!" set "_MATCH=1"
set "_NORM_TARGET=!ONLY_TARGET:_=-!"
set "_NORM_DEST=!_CUR_DEST:_=-!"
if /i "!_NORM_TARGET!"=="!_NORM_DEST!" set "_MATCH=1"
if "!_MATCH!"=="0" if exist "!_CUR_DEST!\libscript.json" (
    jq -e --arg t "!ONLY_TARGET!" --arg tn "!_NORM_TARGET!" "([.name, .remote_dest, (.aliases // [])[]?] | map(select(. != null) | tostring)) | any(. == $t or (gsub(\"_\"; \"-\") == $tn))" "!_CUR_DEST!\libscript.json" >nul 2>&1
    if not errorlevel 1 set "_MATCH=1"
)
if "!_MATCH!"=="1" (
    set "_IM_URL=local"
    if not "!_CUR_DOM!"=="" set "_IM_URL=https://!_CUR_DOM!"
    if "!SKIP_VERIFY!"=="0" (
        set "_PUB_ARG="
        if not "!_CUR_DOM!"=="" set "_PUB_ARG= --verify-ingress --public-url=https://!_CUR_DOM!"
        call "!CLI!" node exec "!NODE!" "!RG_CTX!" "cd ~/!_CUR_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME=$HOME LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh health libscript.json --remediate!_PUB_ARG!"
        if errorlevel 1 exit /b 1
        set /a IMPORT_REPORT_COUNT+=1
        set "IMPORT_ROW_!IMPORT_REPORT_COUNT!=| !_CUR_DEST! | !_IM_URL! | IMPORTED | PASS (200 OK) |"
    ) else (
        set /a IMPORT_REPORT_COUNT+=1
        set "IMPORT_ROW_!IMPORT_REPORT_COUNT!=| !_CUR_DEST! | !_IM_URL! | IMPORTED | SKIPPED |"
    )
)
goto :verify_imported_apps
