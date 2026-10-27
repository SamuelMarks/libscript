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

set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!" >nul 2>&1
if not exist "!LOG_DIR!" set "LOG_DIR=%TEMP%"
set "LOG_FILE=!LOG_DIR!\deploy-%RANDOM%.log"

call :log "INIT" "Starting !PROVIDER! deployment for !NODE! in !LOC! (target: !ONLY_TARGET!)..."

set "VNET_NAME=!NODE!-vnet"
set "NSG_NAME=!NODE!-nsg"
set "AZURE_LOCATION=!LOC!"
set "LOCATION=!LOC!"

set "CLI=!LIBSCRIPT_ROOT_DIR!\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
    call :log "ERROR" "Provider !PROVIDER! not supported (!CLI! missing)."
    exit /b 1
)

call :ensure_cli "jq" "jq"
if /i "!PROVIDER!"=="azure" call :ensure_cli "az" "azure-cli"
if /i "!PROVIDER!"=="aws" call :ensure_cli "aws" "awscli"
if /i "!PROVIDER!"=="gcp" call :ensure_cli "gcloud" "google-cloud-sdk"

if "!APP_SPECS!"=="" (
    if exist "!REPO_PATH!\libscript.json" (
        jq -e ".applications != null and (.applications | length > 0)" "!REPO_PATH!\libscript.json" >nul 2>&1
        if not errorlevel 1 (
            for /f "delims=" %%M in ('jq -r ".applications[] | \"\(.path // .name):\(.remote_dest // .name)@\(.domain // \"\")\"" "!REPO_PATH!\libscript.json" 2^>nul') do (
                set "_MA_LINE=%%M"
                for /f "tokens=1* delims=:" %%P in ("!_MA_LINE!") do (
                    set "_MA_P=%%P"
                    set "_MA_REST=%%Q"
                    if "!_MA_P:~1,1!"==":" (
                        set "APP_SPECS=!APP_SPECS!!_MA_P!:!_MA_REST!|"
                    ) else (
                        set "APP_SPECS=!APP_SPECS!!REPO_PATH!\!_MA_P!:!_MA_REST!|"
                    )
                )
            )
        )
    )
    if "!APP_SPECS!"=="" (
        if "!REMOTE_DEST!"=="" set "REMOTE_DEST=!NODE!"
        set "APP_SPECS=!REPO_PATH!:!REMOTE_DEST!|"
    )
)

set "MANIFEST_FILES="
set "_REM_MF=!APP_SPECS!"
:: ## collect_manifests_loop
:: Collects libscript.json paths across all configured APP_SPECS.
:collect_manifests_loop
if "!_REM_MF!"=="" goto :collect_manifests_done
for /f "tokens=1* delims=|" %%A in ("!_REM_MF!") do (
    set "_MF_SPEC=%%A"
    set "_REM_MF=%%B"
)
call :parse_spec "!_MF_SPEC!"
if exist "!_SP_REPO!\libscript.json" (
    set "MANIFEST_FILES=!MANIFEST_FILES! \"!_SP_REPO!\libscript.json\""
)
goto :collect_manifests_loop

:: ## collect_manifests_done
:: Finalizes manifest collection and extracts node and port configurations.
:collect_manifests_done
set "JSON_FILE=!REPO_PATH!\libscript.json"
if not exist "!JSON_FILE!" (
    for %%F in (!MANIFEST_FILES!) do (
        if not exist "!JSON_FILE!" set "JSON_FILE=%%~F"
    )
)

if exist "!JSON_FILE!" (
    if "!VM_OS!"=="" (
        for /f "delims=" %%O in ('jq -r ".infrastructure.node.os // empty" "!JSON_FILE!" 2^>nul') do set "VM_OS=%%O"
    )
    if "!VM_SIZE!"=="" (
        for /f "delims=" %%S in ('jq -r ".infrastructure.node.size // empty" "!JSON_FILE!" 2^>nul') do set "VM_SIZE=%%S"
    )
    if "!ADMIN_USER!"=="" (
        for /f "delims=" %%U in ('jq -r ".infrastructure.node.admin_user // empty" "!JSON_FILE!" 2^>nul') do set "ADMIN_USER=%%U"
    )
)
if "!VM_OS!"=="" set "VM_OS=Ubuntu2204"
if "!ADMIN_USER!"=="" set "ADMIN_USER=azureuser"

set "PORTS=22 80 443 3000 4200 8000 8001"
if not "!MANIFEST_FILES!"=="" (
    for /f "delims=" %%P in ('jq -r "([22, 80, 443, .infrastructure.network.ports[]?, (.ingress.listen | if type == \"array\" then .[] elif type == \"number\" or type == \"string\" then . else empty end), (.services | if type == \"object\" then .[].port? elif type == \"array\" then .[].port? else empty end)] | map(select(. != null and . != \"\")) | map(tostring) | unique | join(\" \"))" !MANIFEST_FILES! 2^>nul') do (
        if not "%%P"=="" set "PORTS=%%P"
    )
)

set "CTX=!RG!"
if /i "!PROVIDER!"=="aws" set "CTX=!LOC!"
if /i "!PROVIDER!"=="gcp" set "CTX=!LOC!"

if "!SKIP_INFRA!"=="0" (
    if /i "!PROVIDER!"=="azure" (
        call :log "INFRA" "Ensuring Resource Group '!RG!' in '!LOC!'..."
        call :run_with_auth_check "!CLI!" group ensure "!RG!" --location "!LOC!"
        if errorlevel 1 exit /b 1
    )
    call :log "INFRA" "Ensuring Network (!VNET_NAME!)..."
    call :run_with_auth_check "!CLI!" network create "!VNET_NAME!" "!CTX!" --location "!LOC!"
    if errorlevel 1 exit /b 1
    call :log "INFRA" "Ensuring Firewall (!NSG_NAME!) with ports: !PORTS!..."
    call :run_with_auth_check "!CLI!" firewall create "!NSG_NAME!" "!CTX!" "!PORTS!" --location "!LOC!"
    if errorlevel 1 exit /b 1
    set "_SIZE_ARG="
    if not "!VM_SIZE!"=="" set "_SIZE_ARG=--size !VM_SIZE!"
    call :log "INFRA" "Ensuring Compute Node (!NODE!)..."
    call :run_with_auth_check "!CLI!" node create "!NODE!" "!VM_OS!" "!CTX!" !_SIZE_ARG! --vnet-name "!VNET_NAME!" --nsg "!NSG_NAME!" --admin-username "!ADMIN_USER!"
    if errorlevel 1 exit /b 1
    if exist "!JSON_FILE!" if "!DRY_RUN_MODE!"=="0" (
        for /f "delims=" %%D in ('jq -c ".infrastructure.node.data_disks[]? // empty" "!JSON_FILE!" 2^>nul') do (
            set "_DISK_OBJ=%%D"
            call :attach_manifest_disk
        )
    )
)

call :log "SYNC" "Syncing LibScript runtime to '!NODE!'..."
call :run_with_auth_check "!CLI!" node sync "!NODE!" "!CTX!"
if errorlevel 1 exit /b 1

set "PREPARED_STORAGE=0"
if exist "!REPO_PATH!\libscript.json" (
    jq -e ".applications != null and (.applications | length > 0)" "!REPO_PATH!\libscript.json" >nul 2>&1
    if not errorlevel 1 (
        call :log "CONFIG" "Uploading shared-stack manifest '!REPO_PATH!\libscript.json' to '!NODE!'..."
        call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!REPO_PATH!\libscript.json" "libscript.json"
        set "_SHARED_FLAGS="
        if "!FORCE_REINSTALL!"=="1" set "_SHARED_FLAGS=!_SHARED_FLAGS! --force-reinstall"
        if "!SKIP_PREPARE!"=="0" (
            call :log "PREPARE" "Preparing shared persistent storage, runtimes, and databases on '!NODE!' from root manifest..."
            call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~ && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh prepare-storage libscript.json && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh install-deps libscript.json!_SHARED_FLAGS!"
            if errorlevel 1 exit /b 1
            set "PREPARED_STORAGE=1"
        ) else (
            call :log "PREPARE" "Provisioning shared runtimes and databases on '!NODE!' from root manifest..."
            call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~ && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh install-deps libscript.json!_SHARED_FLAGS!"
            if errorlevel 1 exit /b 1
        )
    )
)
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
call :log "DONE" "Deployment complete. View full logs at !LOG_FILE!"
exit /b 0

:: ## log
:: Emits a timestamped stage log message to stdout and appends to LOG_FILE.
:log
set "_L_TAG=%~1"
set "_L_MSG=%~2"
echo [%_L_TAG%] %_L_MSG%
if defined LOG_FILE echo %DATE% %TIME% [%_L_TAG%] %_L_MSG%>> "!LOG_FILE!"
exit /b 0

:: ## run_with_auth_check
:: Executes a provider CLI command, streams filtered output, logs to LOG_FILE, and retries on auth errors.
:run_with_auth_check
if "!DRY_RUN_MODE!"=="1" (
    call %*
    exit /b !ERRORLEVEL!
)
set "_AUTH_TMP=!LOG_DIR!\auth_check_%RANDOM%.tmp"
call %* > "!_AUTH_TMP!" 2>&1
set "_RWAC_RC=!ERRORLEVEL!"
if exist "!_AUTH_TMP!" (
    type "!_AUTH_TMP!" >> "!LOG_FILE!"
    for /f "usebackq delims=" %%L in ("!_AUTH_TMP!") do (
        set "_LINE=%%L"
        set "_SKIP_LINE=0"
        if not "%LIBSCRIPT_DEBUG%"=="1" (
            if "!_LINE:~0,22!"=="[CONTINUE] processing " set "_SKIP_LINE=1"
            if "!_LINE:~0,22!"=="[STOP]     processing " set "_SKIP_LINE=1"
            if "!_LINE!"=="hello world!" set "_SKIP_LINE=1"
        )
        if "!_SKIP_LINE!"=="0" echo !_LINE!
    )
)
if "!_RWAC_RC!"=="0" (
    if exist "!_AUTH_TMP!" del /f /q "!_AUTH_TMP!" >nul 2>&1
    exit /b 0
)
findstr /I /C:"not logged in" /C:"az login" /C:"AuthenticationError" "!_AUTH_TMP!" >nul 2>&1
if not errorlevel 1 (
    call :log "AUTH" "Authentication error detected for azure."
    call az login
    call %*
    set "_RWAC_RC=!ERRORLEVEL!"
)
if exist "!_AUTH_TMP!" del /f /q "!_AUTH_TMP!" >nul 2>&1
exit /b !_RWAC_RC!

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

:: ## ensure_cli
:: Ensures a required CLI binary is available in PATH or installs its LibScript package.
:ensure_cli
set "_EC_CMD=%~1"
set "_EC_PKG=%~2"
if "!DRY_RUN_MODE!"=="1" exit /b 0
where "!_EC_CMD!" >nul 2>&1
if not errorlevel 1 exit /b 0
call :log "INFO" "Command '!_EC_CMD!' not found. Installing '!_EC_PKG!' via LibScript..."
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install "!_EC_PKG!" "latest"
if errorlevel 1 (
    call :log "ERROR" "Failed to auto-install !_EC_PKG!."
    exit /b 1
)
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
for %%C in ("!LIBSCRIPT_HOME!\!_EC_PKG!\default\bin" "!LIBSCRIPT_HOME!\!_EC_PKG!\latest\bin") do (
    echo ";!PATH!;" | findstr /I /C:";%%~C;" >nul 2>&1
    if errorlevel 1 set "PATH=%%~C;!PATH!"
)
for /d %%D in ("!LIBSCRIPT_ROOT_DIR!\_lib\*") do (
    if exist "%%D\!_EC_PKG!\env.cmd" (
        set "STACK="
        call "%%D\!_EC_PKG!\env.cmd"
    )
)
exit /b 0

:: ## attach_manifest_disk
:: Attaches a declarative data disk from _DISK_OBJ onto the target node.
:attach_manifest_disk
set "_D_SIZE=100"
set "_D_MOUNT=/mnt/data"
set "_D_NAME=data-disk"
for /f "delims=" %%S in ('echo !_DISK_OBJ! ^| jq -r ".size_gb // 100" 2^>nul') do set "_D_SIZE=%%S"
for /f "delims=" %%M in ('echo !_DISK_OBJ! ^| jq -r ".mount_path // \"/mnt/data\"" 2^>nul') do set "_D_MOUNT=%%M"
for /f "delims=" %%N in ('echo !_DISK_OBJ! ^| jq -r ".name // \"data-disk\"" 2^>nul') do set "_D_NAME=%%N"
call :log "STORAGE" "Ensuring persistent data disk '!NODE!-!_D_NAME!' (!_D_SIZE!GB -> !_D_MOUNT!)..."
call :run_with_auth_check "!CLI!" storage attach-disk "!NODE!" "!CTX!" "!NODE!-!_D_NAME!" "!_D_SIZE!" "!_D_MOUNT!"
exit /b 0

:: ## check_only_match
:: Sets _MATCH=1 if the given remote destination or manifest matches ONLY_TARGET.
:check_only_match
set "_CHK_DEST=%~1"
set "_CHK_REPO=%~2"
set "_MATCH=0"
if /i "!ONLY_TARGET!"=="all" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="both" set "_MATCH=1"
if /i "!ONLY_TARGET!"=="!_CHK_DEST!" set "_MATCH=1"
set "_NORM_TARGET=!ONLY_TARGET:_=-!"
set "_NORM_DEST=!_CHK_DEST:_=-!"
if /i "!_NORM_TARGET!"=="!_NORM_DEST!" set "_MATCH=1"
if "!_MATCH!"=="0" if not "!_CHK_REPO!"=="" if exist "!_CHK_REPO!\libscript.json" (
    jq -e --arg t "!ONLY_TARGET!" --arg tn "!_NORM_TARGET!" "([.name, .remote_dest, (.aliases // [])[]?] | map(select(. != null) | tostring)) | any(. == $t or (gsub(\"_\"; \"-\") == $tn))" "!_CHK_REPO!\libscript.json" >nul 2>&1
    if not errorlevel 1 set "_MATCH=1"
)
exit /b 0

:: ## deploy_one_spec
:: Deploys a single application specification onto the shared node across explicit phases.
:deploy_one_spec
call :parse_spec "%~1"
call :check_only_match "!_SP_DEST!" "!_SP_REPO!"
if "!_MATCH!"=="0" exit /b 0

call :log "DEPLOY" "Deploying '!_SP_DEST!' ('!_SP_REPO!' -> '!_SP_DEST!', domain: '!_SP_DOMAIN!')..."
call :run_with_auth_check "!CLI!" node deploy "!NODE!" "!CTX!" "!_SP_REPO!" "!_SP_DEST!"
if errorlevel 1 exit /b 1

if exist "!_SP_REPO!\.env" (
    call :log "CONFIG" "Uploading .env for !_SP_DEST!..."
    call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!_SP_REPO!\.env" "!_SP_DEST!/.env"
    if errorlevel 1 exit /b 1
)
if exist "!_SP_REPO!\.env.secrets" (
    call :log "CONFIG" "Uploading .env.secrets for !_SP_DEST!..."
    call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!_SP_REPO!\.env.secrets" "!_SP_DEST!/.env.secrets"
    if errorlevel 1 exit /b 1
)

if "!SKIP_PREPARE!"=="0" if "!PREPARED_STORAGE!"=="0" (
    call :log "PREPARE" "Preparing persistent storage and daemon overrides on '!NODE!' via LibScript..."
    call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh prepare-storage libscript.json"
    if errorlevel 1 exit /b 1
    set "PREPARED_STORAGE=1"
)

set "_DEPS_FLAGS="
if "!FORCE_REINSTALL!"=="1" set "_DEPS_FLAGS=!_DEPS_FLAGS! --force-reinstall"
if "!FORCE_REBUILD!"=="1" set "_DEPS_FLAGS=!_DEPS_FLAGS! --force-rebuild"

call :log "DEPS" "Resolving dependencies, provisioning databases, running data upserts, and building bundles for '!_SP_DEST!'..."
call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh install-deps libscript.json!_DEPS_FLAGS!"
if errorlevel 1 exit /b 1

call :log "DAEMON" "Registering and starting/restarting application daemons for '!_SP_DEST!'..."
call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" LIBSCRIPT_SKIP_DB_INIT=1 $HOME/libscript/libscript.sh start libscript.json --skip-db-init"
if errorlevel 1 exit /b 1

call :log "ROUTES" "Updating reverse-proxy routes and reloading ingress for '!_SP_DEST!' (!NODE!)..."
call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh netctl ingress libscript.json"
exit /b !ERRORLEVEL!

:: ## verify_one_spec
:: Verifies health and ingress for a single deployed application specification.
:verify_one_spec
call :parse_spec "%~1"
call :check_only_match "!_SP_DEST!" "!_SP_REPO!"
if "!_MATCH!"=="0" exit /b 0
set "_PUB_ARG="
if not "!_SP_DOMAIN!"=="" set "_PUB_ARG= --verify-ingress --public-url=https://!_SP_DOMAIN!"
call :log "HEALTH" "Verifying '!_SP_DEST!' health and ingress (!NODE!)..."
call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME="$HOME" LIBSCRIPT_HOME="$HOME/.libscript" LIBSCRIPT_ROOT_DIR="$HOME/libscript" $HOME/libscript/libscript.sh health libscript.json --remediate!_PUB_ARG!"
exit /b !ERRORLEVEL!
