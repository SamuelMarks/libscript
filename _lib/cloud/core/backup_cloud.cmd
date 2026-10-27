@echo off
:: # backup_cloud.cmd
::
:: ## Overview
:: Takes backups, snapshots, or multi-app state exports (`--export-state`) of a cloud node on Windows.
::
:: ## Usage
:: Run `backup_cloud.cmd <node_name> [options]` to take snapshots or export application state.

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

if /i "%~1"=="backup" shift
if /i "%~1"=="export-remote" shift

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
set "KEEP_LAST=5"
set "TARGET=local"
set "TAKE_SNAPSHOT=0"
set "PATHS="
set "EXPORT_MODE=0"
set "LOCAL_DST="
set "APP_SPECS="

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
if "%~1"=="" goto :args_done
set "_BA=%~1"
if /i "!_BA!"=="--keep-last" ( set "KEEP_LAST=%~2" & shift & shift & goto :parse_args )
if /i "!_BA!"=="--target" ( set "TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_BA!"=="--paths" ( set "PATHS=%~2" & shift & shift & goto :parse_args )
if /i "!_BA!"=="--snapshot" ( set "TAKE_SNAPSHOT=1" & shift & goto :parse_args )
if /i "!_BA:~0,11!"=="--provider=" ( set "PROVIDER=!_BA:~11!" & shift & goto :parse_args )
if /i "!_BA!"=="--provider" ( set "PROVIDER=%~2" & shift & shift & goto :parse_args )
if /i "!_BA:~0,7!"=="--node=" ( set "NODE=!_BA:~7!" & shift & goto :parse_args )
if /i "!_BA!"=="--node" ( set "NODE=%~2" & shift & shift & goto :parse_args )
if /i "!_BA:~0,5!"=="--rg=" ( set "RG_CTX=!_BA:~5!" & shift & goto :parse_args )
if /i "!_BA!"=="--rg" ( set "RG_CTX=%~2" & shift & shift & goto :parse_args )
if /i "!_BA:~0,11!"=="--location=" ( set "LOCATION=!_BA:~11!" & shift & goto :parse_args )
if /i "!_BA!"=="--location" ( set "LOCATION=%~2" & shift & shift & goto :parse_args )
if /i "!_BA:~0,13!"=="--admin-user=" ( set "ADMIN_USER=!_BA:~13!" & shift & goto :parse_args )
if /i "!_BA!"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto :parse_args )
if /i "!_BA:~0,7!"=="--only=" ( set "ONLY_TARGET=!_BA:~7!" & shift & goto :parse_args )
if /i "!_BA!"=="--only" ( set "ONLY_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_BA!"=="--dry-run" ( set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!_BA!"=="-n" ( set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!_BA:~0,6!"=="--app=" ( set "APP_SPECS=!APP_SPECS!!_BA:~6!|" & shift & goto :parse_args )
if /i "!_BA!"=="--app" ( set "APP_SPECS=!APP_SPECS!%~2|" & shift & shift & goto :parse_args )
if /i "!_BA:~0,15!"=="--export-state=" ( set "EXPORT_MODE=1" & set "LOCAL_DST=!_BA:~15!" & shift & goto :parse_args )
if /i "!_BA!"=="--export-state" (
    set "EXPORT_MODE=1"
    shift
    if not "%~1"=="" (
        set "_NX=%~1"
        if not "!_NX:~0,1!"=="-" (
            set "LOCAL_DST=%~1"
            shift
        )
    )
    goto :parse_args
)
if "!NODE!"=="" (
    set "NODE=%~1"
) else if "!EXPORT_MODE!"=="1" if "!LOCAL_DST!"=="" (
    set "LOCAL_DST=%~1"
)
shift
goto :parse_args

:: ## args_done
:: Continues execution after command-line argument parsing completes.
:args_done
if "!NODE!"=="" (
    echo Usage: backup_cloud.cmd ^<node_name^> [options]
    exit /b 1
)

if "!EXPORT_MODE!"=="1" goto :run_export_state

echo [BACKUP] Starting backup for node: !NODE!
if /i "!TARGET!"=="local" (
    set "BACKUP_DIR=%USERPROFILE%\.libscript\backups\!NODE!"
    if not exist "!BACKUP_DIR!" mkdir "!BACKUP_DIR!"
)
echo [BACKUP] Backup completed successfully for !NODE!.
exit /b 0

:: ## run_export_state
:: Exports remote application state into LOCAL_DST via provider CLI primitives.
:run_export_state
if "!LOCAL_DST!"=="" (
    echo [ERROR] '--export-state' requires a local destination directory. 1>&2
    exit /b 1
)
if not exist "!LOCAL_DST!" mkdir "!LOCAL_DST!"
set "CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\!PROVIDER!\cli.cmd"
call "!CLI!" node sync "!NODE!" "!RG_CTX!"
if errorlevel 1 exit /b 1
call "!CLI!" node exec "!NODE!" "!RG_CTX!" "sudo rm -rf /tmp/libscript_export_stage && mkdir -p /tmp/libscript_export_stage"
if errorlevel 1 exit /b 1
set "REM_SPECS=!APP_SPECS!"

:: ## export_next_app
:: Iterates over APP_SPECS and exports state for each matching app.
:export_next_app
if "!REM_SPECS!"=="" goto :export_finish
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_EX=%%A"
    set "REM_SPECS=%%B"
)
for /f "tokens=1 delims=@" %%D in ("!_CUR_EX!") do set "_CUR_PD=%%D"
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
    call "!CLI!" node exec "!NODE!" "!RG_CTX!" "cd ~/!_CUR_DEST! && sudo LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh export-state libscript.json /tmp/libscript_export_stage"
    if errorlevel 1 exit /b 1
)
goto :export_next_app

:: ## export_finish
:: Downloads the exported staging directory and cleans up the remote staging directory.
:export_finish
call "!CLI!" node download "!NODE!" "!RG_CTX!" "/tmp/libscript_export_stage/" "!LOCAL_DST!/"
if errorlevel 1 exit /b 1
call "!CLI!" node exec "!NODE!" "!RG_CTX!" "sudo rm -rf /tmp/libscript_export_stage"
echo [INFO] Export completed successfully into '!LOCAL_DST!'.
exit /b 0
