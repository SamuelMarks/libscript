@echo off
:: # teardown_cloud.cmd
::
:: ## Overview
:: Teardown orchestrator for cloud environments and remote applications on Windows.
::
:: ## Usage
:: Run `teardown_cloud.cmd <provider> <node> <rg> <loc> [options]` to cleanly remove apps or destroy infrastructure.

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

if /i "%~1"=="deprovision" shift

set "IS_TPU=0"
set "SHARED_STORAGE=0"
set "RETAIN_IP=0"
set "RETAIN_DATA=0"
set "KEEP_INFRA=0"
set "PURGE_DATA=%PURGE_DATA%"
if "!PURGE_DATA!"=="" set "PURGE_DATA=0"
set "ONLY_TARGET=%ONLY_TARGET%"
if "!ONLY_TARGET!"=="" set "ONLY_TARGET=all"
set "PROVIDER=%CLOUD_PROVIDER%"
if "!PROVIDER!"=="" set "PROVIDER=%PROVIDER%"
set "NODE=%NODE_NAME%"
set "RG=%RG_NAME%"
set "LOC=%LOCATION%"
if "!LOC!"=="" set "LOC=eastus"
set "ADMIN_USER=%ADMIN_USER%"
if "!ADMIN_USER!"=="" set "ADMIN_USER=azureuser"
set "APP_SPECS="

set "P1="
set "P2="
set "P3="
set "P4="
set "P5="
set "P6="

:: ## parse_args
:: Parses command-line arguments and populates configuration variables.
:parse_args
set "arg=%~1"
if "!arg!"=="" goto :args_done
if /i "!arg!"=="--tpu" ( set "IS_TPU=1" & shift & goto :parse_args )
if /i "!arg!"=="--accelerator" ( set "IS_TPU=1" & shift & goto :parse_args )
if /i "!arg!"=="--shared-storage" ( set "SHARED_STORAGE=1" & shift & goto :parse_args )
if /i "!arg!"=="--retain-ip" ( set "RETAIN_IP=1" & shift & goto :parse_args )
if /i "!arg!"=="--retain-data" ( set "RETAIN_DATA=1" & shift & goto :parse_args )
if /i "!arg!"=="--keep-infra" ( set "KEEP_INFRA=1" & shift & goto :parse_args )
if /i "!arg!"=="--remove-app" ( set "KEEP_INFRA=1" & shift & goto :parse_args )
if /i "!arg!"=="--purge-data" ( set "PURGE_DATA=1" & shift & goto :parse_args )
if /i "!arg!"=="--dry-run" ( set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!arg!"=="-n" ( set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!arg:~0,7!"=="--only=" ( set "ONLY_TARGET=!arg:~7!" & shift & goto :parse_args )
if /i "!arg!"=="--only" ( set "ONLY_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!arg:~0,11!"=="--provider=" ( set "PROVIDER=!arg:~11!" & shift & goto :parse_args )
if /i "!arg!"=="--provider" ( set "PROVIDER=%~2" & shift & shift & goto :parse_args )
if /i "!arg:~0,7!"=="--node=" ( set "NODE=!arg:~7!" & shift & goto :parse_args )
if /i "!arg!"=="--node" ( set "NODE=%~2" & shift & shift & goto :parse_args )
if /i "!arg:~0,5!"=="--rg=" ( set "RG=!arg:~5!" & shift & goto :parse_args )
if /i "!arg!"=="--rg" ( set "RG=%~2" & shift & shift & goto :parse_args )
if /i "!arg:~0,11!"=="--location=" ( set "LOC=!arg:~11!" & shift & goto :parse_args )
if /i "!arg!"=="--location" ( set "LOC=%~2" & shift & shift & goto :parse_args )
if /i "!arg:~0,13!"=="--admin-user=" ( set "ADMIN_USER=!arg:~13!" & shift & goto :parse_args )
if /i "!arg!"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto :parse_args )
if /i "!arg:~0,6!"=="--app=" ( set "APP_SPECS=!APP_SPECS!!arg:~6!|" & set "KEEP_INFRA=1" & shift & goto :parse_args )
if /i "!arg!"=="--app" ( set "APP_SPECS=!APP_SPECS!%~2|" & set "KEEP_INFRA=1" & shift & shift & goto :parse_args )

if "!P1!"=="" ( set "P1=%~1"
) else if "!P2!"=="" ( set "P2=%~1"
) else if "!P3!"=="" ( set "P3=%~1"
) else if "!P4!"=="" ( set "P4=%~1"
) else if "!P5!"=="" ( set "P5=%~1"
) else if "!P6!"=="" ( set "P6=%~1"
)
shift
goto :parse_args

:: ## args_done
:: Continues execution after command-line argument parsing completes.
:args_done
if "!PROVIDER!"=="" set "PROVIDER=!P1!"
if "!NODE!"=="" set "NODE=!P2!"
if "!RG!"=="" set "RG=!P3!"
if not "!P4!"=="" set "LOC=!P4!"
set "REPO_PATH=!P5!"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=!P6!"
if "!REMOTE_DEST!"=="" set "REMOTE_DEST=~/!NODE!"

if "!PROVIDER!"=="" (
    echo Usage: teardown_cloud.cmd ^<provider^> ^<node_name^> ^<rg^> [location] [options]
    exit /b 1
)

set "CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
    echo [ERROR] Provider !PROVIDER! not supported. 1>&2
    exit /b 1
)

set "CTX=!RG!"
if /i "!PROVIDER!"=="aws" set "CTX=!LOC!"
if /i "!PROVIDER!"=="gcp" set "CTX=!LOC!"

if "!KEEP_INFRA!"=="1" if not "!APP_SPECS!"=="" goto :remove_apps_mode

if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Simulated deprovision for !PROVIDER! !NODE! !RG! !LOC!
    exit /b 0
)

call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh stop"
call "!CLI!" node delete "!NODE!" "!CTX!"
if /i "!PROVIDER!"=="azure" (
    call "!CLI!" firewall delete "!NODE!-nsg" "!RG!"
    call "!CLI!" network delete "!NODE!-vnet" "!RG!"
)
echo [DONE] Teardown complete.
exit /b 0

:: ## remove_apps_mode
:: Decommissions selected application(s) from the shared node without deleting the VM.
:remove_apps_mode
call "!CLI!" node sync "!NODE!" "!CTX!"
if errorlevel 1 exit /b 1
set "_PURGE_FLAG="
if "!PURGE_DATA!"=="1" set "_PURGE_FLAG= --purge-data"
set "REM_SPECS=!APP_SPECS!"

:: ## remove_next_app
:: Iterates over APP_SPECS and decommissions each matching target.
:remove_next_app
if "!REM_SPECS!"=="" (
    echo [INFO] Removal of '!ONLY_TARGET!' completed successfully.
    exit /b 0
)
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_RM=%%A"
    set "REM_SPECS=%%B"
)
for /f "tokens=1 delims=@" %%D in ("!_CUR_RM!") do set "_CUR_PD=%%D"
set "_CUR_DEST="
for /f "tokens=1,2 delims=:" %%P in ("!_CUR_PD!") do (
    if "%%Q"=="" (
        for %%F in ("%%P") do set "_CUR_DEST=%%~nxF"
    ) else (
        set "_CUR_DEST=%%Q"
    )
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
    call "!CLI!" node exec "!NODE!" "!CTX!" "if [ -f ~/!_CUR_DEST!/libscript.json ]; then cd ~/!_CUR_DEST! && sudo LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh down libscript.json --remove!_PURGE_FLAG! && sudo LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh netctl remove-ingress libscript.json; fi; sudo rm -rf ~/!_CUR_DEST!"
    if errorlevel 1 exit /b 1
)
goto :remove_next_app
