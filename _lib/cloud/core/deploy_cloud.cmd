@echo off
:: # deploy_cloud.cmd
::
:: ## Overview
:: Primary deployment orchestrator for Windows, provisioning infrastructure across AWS, Azure, or GCP,
:: and deploying one or more applications onto a single or shared compute node.
::
:: ## Usage
:: Run `deploy_cloud.cmd [options] <provider> <node> <rg> <loc> [repo] [dest]` or
:: `deploy_cloud.cmd --provider <p> --node <n> --rg <rg> --location <loc> [--app <repo>[:<dest>][@<domain>]]...`

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if /i "%~1"=="provision" shift

set "IS_TPU=0"
set "SHARED_STORAGE=0"
set "SKIP_INFRA=0"
set "SKIP_PREPARE=0"
set "SKIP_VERIFY=0"
set "FORCE_REINSTALL=%FORCE_REINSTALL%"
if "!FORCE_REINSTALL!"=="" set "FORCE_REINSTALL=0"
set "FORCE_REBUILD=%FORCE_REBUILD%"
if "!FORCE_REBUILD!"=="" set "FORCE_REBUILD=0"
set "ONLY_TARGET=%ONLY_TARGET%"
if "!ONLY_TARGET!"=="" set "ONLY_TARGET=all"
set "DRY_RUN_MODE=0"
if /i "%DRY_RUN%"=="true" set "DRY_RUN_MODE=1"
if "%DRY_RUN%"=="1" set "DRY_RUN_MODE=1"

set "PROVIDER=%CLOUD_PROVIDER%"
if "!PROVIDER!"=="" set "PROVIDER=%PROVIDER%"
set "NODE=%NODE_NAME%"
set "RG=%RG_NAME%"
set "LOC=%LOCATION%"
set "VM_OS=%VM_IMAGE%"
set "VM_SIZE=%VM_SIZE%"
set "ADMIN_USER=%ADMIN_USER%"
set "APP_SPECS="
set "_p1="
set "_p2="
set "_p3="
set "_p4="
set "_p5="
set "_p6="

:: ## parse_args
:: Parses command-line flags and positional parameters.
:parse_args
if "%~1"=="" goto :args_done
set "_A=%~1"
if /i "!_A!"=="--tpu" ( set "IS_TPU=1" & shift & goto :parse_args )
if /i "!_A!"=="--accelerator" ( set "IS_TPU=1" & shift & goto :parse_args )
if /i "!_A!"=="--shared-storage" ( set "SHARED_STORAGE=1" & shift & goto :parse_args )
if /i "!_A!"=="--skip-infra" ( set "SKIP_INFRA=1" & shift & goto :parse_args )
if /i "!_A!"=="--skip-prepare" ( set "SKIP_PREPARE=1" & shift & goto :parse_args )
if /i "!_A!"=="--skip-verify" ( set "SKIP_VERIFY=1" & shift & goto :parse_args )
if /i "!_A!"=="--force-reinstall" ( set "FORCE_REINSTALL=1" & shift & goto :parse_args )
if /i "!_A!"=="--force-rebuild" ( set "FORCE_REBUILD=1" & shift & goto :parse_args )
if /i "!_A!"=="--dry-run" ( set "DRY_RUN_MODE=1" & set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!_A!"=="-n" ( set "DRY_RUN_MODE=1" & set "DRY_RUN=true" & shift & goto :parse_args )
if /i "!_A:~0,7!"=="--only=" ( set "ONLY_TARGET=!_A:~7!" & shift & goto :parse_args )
if /i "!_A!"=="--only" ( set "ONLY_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,11!"=="--provider=" ( set "PROVIDER=!_A:~11!" & shift & goto :parse_args )
if /i "!_A!"=="--provider" ( set "PROVIDER=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,7!"=="--node=" ( set "NODE=!_A:~7!" & shift & goto :parse_args )
if /i "!_A!"=="--node" ( set "NODE=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,5!"=="--rg=" ( set "RG=!_A:~5!" & shift & goto :parse_args )
if /i "!_A!"=="--rg" ( set "RG=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,17!"=="--resource-group=" ( set "RG=!_A:~17!" & shift & goto :parse_args )
if /i "!_A!"=="--resource-group" ( set "RG=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,11!"=="--location=" ( set "LOC=!_A:~11!" & shift & goto :parse_args )
if /i "!_A!"=="--location" ( set "LOC=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,11!"=="--vm-image=" ( set "VM_OS=!_A:~11!" & shift & goto :parse_args )
if /i "!_A!"=="--vm-image" ( set "VM_OS=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,7!"=="--size=" ( set "VM_SIZE=!_A:~7!" & shift & goto :parse_args )
if /i "!_A!"=="--size" ( set "VM_SIZE=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,13!"=="--admin-user=" ( set "ADMIN_USER=!_A:~13!" & shift & goto :parse_args )
if /i "!_A!"=="--admin-user" ( set "ADMIN_USER=%~2" & shift & shift & goto :parse_args )
if /i "!_A:~0,6!"=="--app=" ( set "APP_SPECS=!APP_SPECS!!_A:~6!|" & shift & goto :parse_args )
if /i "!_A!"=="--app" ( set "APP_SPECS=!APP_SPECS!%~2|" & shift & shift & goto :parse_args )

if "!_p1!"=="" ( set "_p1=%~1"
) else if "!_p2!"=="" ( set "_p2=%~1"
) else if "!_p3!"=="" ( set "_p3=%~1"
) else if "!_p4!"=="" ( set "_p4=%~1"
) else if "!_p5!"=="" ( set "_p5=%~1"
) else if "!_p6!"=="" ( set "_p6=%~1"
)
shift
goto :parse_args

:: ## args_done
:: Validates parsed arguments and begins provisioning and deployment.
:args_done
if "!PROVIDER!"=="" set "PROVIDER=!_p1!"
if "!NODE!"=="" set "NODE=!_p2!"
if "!RG!"=="" set "RG=!_p3!"
if "!LOC!"=="" set "LOC=!_p4!"
set "REPO_PATH=!_p5!"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=!_p6!"

if "!PROVIDER!"=="" (
    echo Usage: deploy_cloud.cmd [options] ^<provider^> ^<node_name^> ^<rg^> ^<location^> [repo] [dest]
    exit /b 1
)

if "!VM_OS!"=="" set "VM_OS=Ubuntu2204"
if "!ADMIN_USER!"=="" set "ADMIN_USER=azureuser"
set "VNET_NAME=!NODE!-vnet"
set "NSG_NAME=!NODE!-nsg"
set "AZURE_LOCATION=!LOC!"
set "LOCATION=!LOC!"

set "CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
    echo [ERROR] Provider !PROVIDER! not supported ^(!CLI! missing^). 1>&2
    exit /b 1
)

if "!APP_SPECS!"=="" (
    if "!REMOTE_DEST!"=="" set "REMOTE_DEST=!NODE!"
    set "APP_SPECS=!REPO_PATH!:!REMOTE_DEST!|"
)

set "PORTS=22 80 443 3000 4200 8000 8001"
set "CTX=!RG!"
if /i "!PROVIDER!"=="aws" set "CTX=!LOC!"
if /i "!PROVIDER!"=="gcp" set "CTX=!LOC!"

if "!SKIP_INFRA!"=="0" (
    if /i "!PROVIDER!"=="azure" (
        call "!CLI!" group ensure "!RG!" --location "!LOC!"
        if errorlevel 1 exit /b 1
    )
    call "!CLI!" network create "!VNET_NAME!" "!CTX!" --location "!LOC!"
    if errorlevel 1 exit /b 1
    call "!CLI!" firewall create "!NSG_NAME!" "!CTX!" "!PORTS!" --location "!LOC!"
    if errorlevel 1 exit /b 1
    set "_SIZE_ARG="
    if not "!VM_SIZE!"=="" set "_SIZE_ARG=--size !VM_SIZE!"
    call "!CLI!" node create "!NODE!" "!VM_OS!" "!CTX!" !_SIZE_ARG! --vnet-name "!VNET_NAME!" --nsg "!NSG_NAME!" --admin-username "!ADMIN_USER!"
    if errorlevel 1 exit /b 1
)

call "!CLI!" node sync "!NODE!" "!CTX!"
if errorlevel 1 exit /b 1

set "PREPARED_STORAGE=0"
set "REM_SPECS=!APP_SPECS!"

:: ## deploy_loop
:: Iterates over APP_SPECS and deploys each selected application onto the shared node.
:deploy_loop
if "!REM_SPECS!"=="" goto :verify_loop
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_SPEC=%%A"
    set "REM_SPECS=%%B"
)
call :deploy_one_spec "!_CUR_SPEC!"
if errorlevel 1 exit /b 1
goto :deploy_loop

:: ## verify_loop
:: Runs post-deployment health and public ingress verification on deployed apps.
:verify_loop
if "!SKIP_VERIFY!"=="1" goto :deploy_done
set "REM_SPECS=!APP_SPECS!"

:: ## verify_next
:: Iterates through each deployed app for health verification.
:verify_next
if "!REM_SPECS!"=="" goto :deploy_done
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_SPEC=%%A"
    set "REM_SPECS=%%B"
)
call :verify_one_spec "!_CUR_SPEC!"
if errorlevel 1 exit /b 1
goto :verify_next

:: ## deploy_done
:: Finalizes deployment execution.
:deploy_done
echo [DONE] Deployment complete.
exit /b 0

:: ## parse_spec
:: Parses <repo>[:<dest>][@<domain>] into _SP_REPO, _SP_DEST, and _SP_DOMAIN.
:parse_spec
set "_RAW=%~1"
set "_SP_DOMAIN="
for /f "tokens=1,2 delims=@" %%D in ("!_RAW!") do (
    set "_SP_PD=%%D"
    set "_SP_DOMAIN=%%E"
)
for /f "tokens=1,2 delims=:" %%P in ("!_SP_PD!") do (
    set "_SP_REPO=%%P"
    set "_SP_DEST=%%Q"
)
if "!_SP_DEST!"=="" (
    for %%F in ("!_SP_REPO!") do set "_SP_DEST=%%~nxF"
)
exit /b 0

:: ## check_only_match
:: Sets _MATCH=1 if the given remote destination matches ONLY_TARGET.
:check_only_match
set "_CHK_DEST=%~1"
set "_MATCH=0"
if /i "!ONLY_TARGET!"=="all" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="both" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="!_CHK_DEST!" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="pulse_query" if /i "!_CHK_DEST!"=="hospital-dashboard-platform" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="t1d_analytics" if /i "!_CHK_DEST!"=="t1d-analytics" set "_MATCH=1"
exit /b 0

:: ## deploy_one_spec
:: Deploys a single application specification onto the shared node.
:deploy_one_spec
call :parse_spec "%~1"
call :check_only_match "!_SP_DEST!"
if "!_MATCH!"=="0" exit /b 0

call "!CLI!" node deploy "!NODE!" "!CTX!" "!_SP_REPO!" "!_SP_DEST!"
if errorlevel 1 exit /b 1

if exist "!_SP_REPO!\.env" (
    call "!CLI!" node upload "!NODE!" "!CTX!" "!_SP_REPO!\.env" "!_SP_DEST!/.env"
    if errorlevel 1 exit /b 1
)
if exist "!_SP_REPO!\.env.secrets" (
    call "!CLI!" node upload "!NODE!" "!CTX!" "!_SP_REPO!\.env.secrets" "!_SP_DEST!/.env.secrets"
    if errorlevel 1 exit /b 1
)

if "!SKIP_PREPARE!"=="0" if "!PREPARED_STORAGE!"=="0" (
    call "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh prepare-storage libscript.json"
    if errorlevel 1 exit /b 1
    set "PREPARED_STORAGE=1"
)

set "_DEPS_FLAGS="
if "!FORCE_REINSTALL!"=="1" set "_DEPS_FLAGS=!_DEPS_FLAGS! --force-reinstall"
if "!FORCE_REBUILD!"=="1" set "_DEPS_FLAGS=!_DEPS_FLAGS! --force-rebuild"

call "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh install-deps libscript.json!_DEPS_FLAGS! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh start libscript.json && sudo REMOTE_HOME="$HOME" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh netctl ingress libscript.json"
exit /b !ERRORLEVEL!

:: ## verify_one_spec
:: Verifies health and ingress for a single deployed application specification.
:verify_one_spec
call :parse_spec "%~1"
call :check_only_match "!_SP_DEST!"
if "!_MATCH!"=="0" exit /b 0
set "_PUB_ARG="
if not "!_SP_DOMAIN!"=="" set "_PUB_ARG= --verify-ingress --public-url=https://!_SP_DOMAIN!"
call "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh health libscript.json --remediate!_PUB_ARG!"
exit /b !ERRORLEVEL!
