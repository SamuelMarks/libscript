@echo off
:: # deploy_cloud.cmd
:: ## Overview
:: Primary deployment orchestrator for Windows, provisioning infrastructure across AWS, Azure, or GCP, and deploying one or more applications onto a single or shared compute node.
:: ## Usage
:: Run `deploy_cloud.cmd [options] <provider> <node> <rg> <loc> [repo] [dest]` or `deploy_cloud.cmd --provider <p> --node <n> --rg <rg> --location <loc> [--app <repo>[:<dest>][@<domain>]]...`

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
set "REPO_ROOT_OVERRIDE=%REPO_PATH%"
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
if /i "!_A:~0,12!"=="--repo-root=" ( set "REPO_ROOT_OVERRIDE=!_A:~12!" & shift & goto :parse_args )
if /i "!_A!"=="--repo-root" ( set "REPO_ROOT_OVERRIDE=%~2" & shift & shift & goto :parse_args )
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
set "REPO_PATH=!REPO_ROOT_OVERRIDE!"
if "!REPO_PATH!"=="" set "REPO_PATH=!_p5!"
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

call :validate_shared_node_manifests
if errorlevel 1 exit /b 1
if "!SKIP_INFRA!"=="0" (
    call :log "SSH" "Waiting for SSH readiness on '!NODE!'..."
    call :run_with_auth_check "!CLI!" node wait-ssh "!NODE!" "!CTX!"
)
set "_RT_HASH=nogit"
for /f "delims=" %%H in ('git -C "!LIBSCRIPT_ROOT_DIR!" rev-parse HEAD 2^>nul') do set "_RT_HASH=%%H"
set "_SKIP_RT_SYNC=0"
if "!DRY_RUN_MODE!"=="0" if "!FORCE_REINSTALL!"=="0" if "!FORCE_REBUILD!"=="0" (
    call "!CLI!" node exec "!NODE!" "!CTX!" "[ -x ~/libscript/libscript.sh ] && [ -f ~/.libscript_deployments/_libscript_runtime.sha256 ] && grep -qx '!_RT_HASH!' ~/.libscript_deployments/_libscript_runtime.sha256" >nul 2>&1
    if not errorlevel 1 set "_SKIP_RT_SYNC=1"
)
if "!_SKIP_RT_SYNC!"=="1" (
    call :log "REUSE" "LibScript runtime on '!NODE!' is up-to-date (!_RT_HASH!); skipping node sync."
) else (
    call :log "SYNC" "Syncing LibScript runtime to '!NODE!'..."
    call :run_with_auth_check "!CLI!" node sync "!NODE!" "!CTX!"
    if errorlevel 1 exit /b 1
    if "!DRY_RUN_MODE!"=="0" (
        call "!CLI!" node exec "!NODE!" "!CTX!" "mkdir -p ~/.libscript_deployments && printf '%s\n' '!_RT_HASH!' > ~/.libscript_deployments/_libscript_runtime.sha256" >nul 2>&1
    )
)

set "_DEPLOY_DATA_MOUNT=%DATA_DISK_MOUNT%"
if "!_DEPLOY_DATA_MOUNT!"=="" set "_DEPLOY_DATA_MOUNT=%DATA_MOUNT_DIR%"
if "!_DEPLOY_DATA_MOUNT!"=="" set "_DEPLOY_DATA_MOUNT=/mnt/data"
set "_DEPLOY_OL_MODELS=%OLLAMA_MODELS_DIR%"
if "!_DEPLOY_OL_MODELS!"=="" set "_DEPLOY_OL_MODELS=!_DEPLOY_DATA_MOUNT!/ollama_models"
if "%GGML_BACKEND_AMX%"=="" set "GGML_BACKEND_AMX=0"
if "%OLLAMA_LLM_LIBRARY%"=="" set "OLLAMA_LLM_LIBRARY=cpu_avx2"
if "%OLLAMA_NUM_GPU%"=="" set "OLLAMA_NUM_GPU=0"
if "%OLLAMA_FLASH_ATTENTION%"=="" set "OLLAMA_FLASH_ATTENTION=0"
if "%OLLAMA_KV_CACHE_TYPE%"=="" set "OLLAMA_KV_CACHE_TYPE=f16"
if "%OLLAMA_CONTEXT_LENGTH%"=="" set "OLLAMA_CONTEXT_LENGTH=2048"
if "%OLLAMA_MAX_QUEUE%"=="" set "OLLAMA_MAX_QUEUE=16"
if "%OLLAMA_KEEP_ALIVE%"=="" set "OLLAMA_KEEP_ALIVE=10m"
if "%POSTGRES_DATA_DIR%"=="" set "POSTGRES_DATA_DIR=%PGDATA%"
if "%PGDATA%"=="" set "PGDATA=%POSTGRES_DATA_DIR%"
if "%VALKEY_DATA_DIR%"=="" set "VALKEY_DATA_DIR=%REDIS_DATA_DIR%"
if "%REDIS_DATA_DIR%"=="" set "REDIS_DATA_DIR=%VALKEY_DATA_DIR%"
if "%CERT_STORE_DIR%"=="" set "CERT_STORE_DIR=!_DEPLOY_DATA_MOUNT!/certs"
if "%LETSENCRYPT_RENEW_BEFORE_SECONDS%"=="" set "LETSENCRYPT_RENEW_BEFORE_SECONDS=0"
set "_REMOTE_OLLAMA_ENV=GGML_BACKEND_AMX='!GGML_BACKEND_AMX!' OLLAMA_LLM_LIBRARY='!OLLAMA_LLM_LIBRARY!' OLLAMA_NUM_GPU='!OLLAMA_NUM_GPU!' OLLAMA_FLASH_ATTENTION='!OLLAMA_FLASH_ATTENTION!' OLLAMA_KV_CACHE_TYPE='!OLLAMA_KV_CACHE_TYPE!' OLLAMA_CONTEXT_LENGTH='!OLLAMA_CONTEXT_LENGTH!' OLLAMA_MAX_QUEUE='!OLLAMA_MAX_QUEUE!' OLLAMA_KEEP_ALIVE='!OLLAMA_KEEP_ALIVE!' POSTGRES_DATA_DIR='!POSTGRES_DATA_DIR!' PGDATA='!PGDATA!' VALKEY_DATA_DIR='!VALKEY_DATA_DIR!' REDIS_DATA_DIR='!REDIS_DATA_DIR!' CERT_STORE_DIR='!CERT_STORE_DIR!' LETSENCRYPT_EMAIL='!LETSENCRYPT_EMAIL!' LETSENCRYPT_RENEW_BEFORE_SECONDS='!LETSENCRYPT_RENEW_BEFORE_SECONDS!'"

set "PREPARED_STORAGE=0"
if exist "!REPO_PATH!\libscript.json" (
    jq -e ".applications != null and (.applications | length > 0)" "!REPO_PATH!\libscript.json" >nul 2>&1
    if not errorlevel 1 (
        set "_ROOT_MF_HASH=0"
        for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!REPO_PATH!\libscript.json" SHA256 2^>nul') do (
            if "!_ROOT_MF_HASH!"=="0" set "_ROOT_MF_HASH=%%H"
        )
        set "_SKIP_ROOT_PREP=0"
        if "!DRY_RUN_MODE!"=="0" if "!FORCE_REINSTALL!"=="0" if "!FORCE_REBUILD!"=="0" (
            call "!CLI!" node exec "!NODE!" "!CTX!" "[ -f ~/libscript.json ] && [ -f ~/.libscript_deployments/_root_manifest.sha256 ] && grep -qx '!_ROOT_MF_HASH!' ~/.libscript_deployments/_root_manifest.sha256" >nul 2>&1
            if not errorlevel 1 (
                set "_SKIP_ROOT_PREP=1"
                set "PREPARED_STORAGE=1"
            )
        )
        if "!_SKIP_ROOT_PREP!"=="1" (
            call :log "REUSE" "Shared-stack root manifest '!REPO_PATH!\libscript.json' (!_ROOT_MF_HASH!) unchanged; skipping root prepare-storage and install-deps."
            if "!DRY_RUN_MODE!"=="0" if "!SKIP_PREPARE!"=="0" (
                call :prepare_remote_jaeb_storage
                call "!CLI!" node exec "!NODE!" "!CTX!" "if id ollama >/dev/null 2>&1 && [ -d '!_DEPLOY_OL_MODELS!' ]; then sudo chown -R ollama:ollama '!_DEPLOY_OL_MODELS!' 2>/dev/null || true; sudo chmod 02775 '!_DEPLOY_OL_MODELS!' 2>/dev/null || true; sudo chmod -R u+rwX,g+rwXs,o+rX '!_DEPLOY_OL_MODELS!' 2>/dev/null || true; fi && if [ -x $HOME/libscript/_lib/app-servers/ollama/service.sh ] && [ -d '!_DEPLOY_OL_MODELS!' ]; then sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! OLLAMA_MODELS_DIR='!_DEPLOY_OL_MODELS!' OLLAMA_MODELS='!_DEPLOY_OL_MODELS!' LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/_lib/app-servers/ollama/service.sh configure >/dev/null 2>&1 || true; fi" >nul 2>&1
            )
        ) else (
            call :log "CONFIG" "Uploading shared-stack manifest '!REPO_PATH!\libscript.json' to '!NODE!'..."
            call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!REPO_PATH!\libscript.json" "libscript.json"
            set "_SHARED_FLAGS="
            if "!FORCE_REINSTALL!"=="1" set "_SHARED_FLAGS=!_SHARED_FLAGS! --force-reinstall"
            if "!SKIP_PREPARE!"=="0" (
                call :log "PREPARE" "Preparing shared persistent storage, runtimes, and databases on '!NODE!' from root manifest..."
                call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~ && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh prepare-storage libscript.json && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh install-deps libscript.json!_SHARED_FLAGS!"
                if errorlevel 1 exit /b 1
                call :prepare_remote_jaeb_storage
                set "PREPARED_STORAGE=1"
            ) else (
                call :log "PREPARE" "Provisioning shared runtimes and databases on '!NODE!' from root manifest..."
                call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~ && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh install-deps libscript.json!_SHARED_FLAGS!"
                if errorlevel 1 exit /b 1
            )
            if "!DRY_RUN_MODE!"=="0" (
                call "!CLI!" node exec "!NODE!" "!CTX!" "mkdir -p ~/.libscript_deployments && printf '%s\n' '!_ROOT_MF_HASH!' > ~/.libscript_deployments/_root_manifest.sha256" >nul 2>&1
            )
        )
    )
)
if "!SKIP_PREPARE!"=="0" if "!PREPARED_STORAGE!"=="0" (
    call :prepare_remote_jaeb_storage
)
set "IP=203.0.113.10"
if "!DRY_RUN_MODE!"=="0" (
    for /f "delims=" %%I in ('call "!CLI!" node ip "!NODE!" "!CTX!" 2^>nul') do (
        if not "%%I"=="" set "IP=%%I"
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
:: Discovers node IP, ensures DNS records, and runs post-deployment health and public ingress verification.
:verify_loop
if "!IP!"=="" set "IP=203.0.113.10"
set "REPORT_COUNT=0"
set "OVERALL_VERIFY_FAILED=0"
set "REM_SPECS=!APP_SPECS!"

:: ## verify_next
:: Iterates through each deployed app for DNS binding, health verification, and report row generation.
:verify_next
if "!REM_SPECS!"=="" goto :deploy_done
for /f "tokens=1* delims=|" %%A in ("!REM_SPECS!") do (
    set "_CUR_SPEC=%%A"
    set "REM_SPECS=%%B"
)
call :verify_one_spec "!_CUR_SPEC!"
if errorlevel 1 (
    set "OVERALL_VERIFY_FAILED=1"
)
goto :verify_next

:: ## deploy_done
:: Prints the ASCII deployment summary table and finalizes deployment execution.
:deploy_done
call :print_deployment_report
if not "!OVERALL_VERIFY_FAILED!"=="0" (
    call :log "ERROR" "One or more deployed applications failed verification. View full logs at !LOG_FILE!"
    exit /b 1
)
call :log "DONE" "Deployment complete. View full logs at !LOG_FILE!"
exit /b 0

:: ## print_deployment_report
:: Renders an ASCII deployment summary table with per-app healthcheck status, DNS records, and public URLs.
:print_deployment_report
echo +------------------------------------------------------------------------------------------------------------------+
echo ^| LIBSCRIPT CLOUD DEPLOYMENT REPORT ^(Provider: !PROVIDER! ^| Node: !NODE! ^| Context: !CTX! ^| IP: !IP!^)
echo +----------------------------+------------------------+----------------------------------+-------------+-----------+
echo ^| Application                ^| Remote Directory       ^| DNS Name / Public Endpoint       ^| Healthcheck ^| Ingress   ^|
echo +----------------------------+------------------------+----------------------------------+-------------+-----------+
for /L %%I in (1,1,!REPORT_COUNT!) do (
    echo !REPORT_ROW_%%I!
)
echo +----------------------------+------------------------+----------------------------------+-------------+-----------+
echo ^| SSH Access : ssh !ADMIN_USER!@!IP!
echo ^| Log File   : !LOG_FILE!
echo +------------------------------------------------------------------------------------------------------------------+
if defined LOG_FILE (
    echo +------------------------------------------------------------------------------------------------------------------+>> "!LOG_FILE!"
    echo ^| LIBSCRIPT CLOUD DEPLOYMENT REPORT ^(Provider: !PROVIDER! ^| Node: !NODE! ^| Context: !CTX! ^| IP: !IP!^)>> "!LOG_FILE!"
    for /L %%I in (1,1,!REPORT_COUNT!) do (
        echo !REPORT_ROW_%%I!>> "!LOG_FILE!"
    )
    echo +------------------------------------------------------------------------------------------------------------------+>> "!LOG_FILE!"
)
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
findstr /I /C:"not logged in" /C:"az login" /C:"AuthenticationError" /C:"ExpiredToken" /C:"InvalidClientTokenId" /C:"Unable to locate credentials" /C:"gcloud auth login" /C:"Reauthentication required" "!_AUTH_TMP!" >nul 2>&1
if not errorlevel 1 (
    call :log "AUTH" "Authentication error detected for !PROVIDER!."
    if /i "!PROVIDER!"=="azure" call az login
    if /i "!PROVIDER!"=="aws" call aws configure
    if /i "!PROVIDER!"=="gcp" call gcloud auth login
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
set "_D_MOUNT=!_DEPLOY_DATA_MOUNT!"
if "!_D_MOUNT!"=="" set "_D_MOUNT=%DATA_DISK_MOUNT%"
if "!_D_MOUNT!"=="" set "_D_MOUNT=%DATA_MOUNT_DIR%"
if "!_D_MOUNT!"=="" set "_D_MOUNT=/mnt/data"
set "_D_NAME=data-disk"
for /f "delims=" %%S in ('echo !_DISK_OBJ! ^| jq -r ".size_gb // 100" 2^>nul') do set "_D_SIZE=%%S"
for /f "delims=" %%M in ('echo !_DISK_OBJ! ^| jq -r --arg def "!_D_MOUNT!" ".mount_path // $def" 2^>nul') do set "_D_MOUNT=%%M"
for /f "delims=" %%N in ('echo !_DISK_OBJ! ^| jq -r ".name // \"data-disk\"" 2^>nul') do set "_D_NAME=%%N"
set "_FULL_D_NAME=!NODE!-!_D_NAME!"
echo "!_D_NAME!" | findstr /B /I /C:"!NODE!-" >nul 2>&1
if not errorlevel 1 set "_FULL_D_NAME=!_D_NAME!"
call :log "STORAGE" "Ensuring persistent data disk '!_FULL_D_NAME!' (!_D_SIZE!GB -> !_D_MOUNT!)..."
call :run_with_auth_check "!CLI!" storage attach-disk "!NODE!" "!CTX!" "!_FULL_D_NAME!" "!_D_SIZE!" "!_D_MOUNT!"
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

set "_DEPS_FLAGS="
if "!FORCE_REINSTALL!"=="1" set "_DEPS_FLAGS=!_DEPS_FLAGS! --force-reinstall"
if "!FORCE_REBUILD!"=="1" set "_DEPS_FLAGS=!_DEPS_FLAGS! --force-rebuild"

call :compute_app_checksum "!_SP_REPO!"
set "_ART_CMD=true"
if exist "!_SP_REPO!\libscript.json" (
    for /f "delims=" %%K in ('jq -r "([ (.frontends | if type == \"array\" then .[].artifact_check? elif type == \"object\" then .[].artifact_check? else empty end), (.hooks.build[]?.artifact_check?) ] | map(select(. != null and . != \"\")) | unique)[]?" "!_SP_REPO!\libscript.json" 2^>nul') do (
        set "_ART_CMD=!_ART_CMD! && [ -e ~/!_SP_DEST!/%%K ]"
    )
    for /f "delims=" %%F in ('jq -r "([ (.frontends | if type == \"array\" then .[] elif type == \"object\" then .[] else empty end | (.source_dir // .working_dir // .cwd // \".\")) ] | map(select(. != null and . != \"\")) | unique)[]?" "!_SP_REPO!\libscript.json" 2^>nul') do (
        set "_FE_REL=%%F"
        if "!_FE_REL!"=="." (
            set "_FE_PFX=~/!_SP_DEST!"
        ) else (
            set "_FE_PFX=~/!_SP_DEST!/!_FE_REL!"
        )
        set "_ART_CMD=!_ART_CMD! && [ -f !_FE_PFX!/node_modules/.libscript_pkg_hash ] && { [ -f !_FE_PFX!/.libscript_build.sha256 ] || [ -f !_FE_PFX!/dist/.libscript_src_hash ]; }"
    )
)
if exist "!_SP_REPO!\pyproject.toml" (
    set "_ART_CMD=!_ART_CMD! && [ -f ~/!_SP_DEST!/.venv/.libscript_lock_hash ]"
) else if exist "!_SP_REPO!\uv.lock" (
    set "_ART_CMD=!_ART_CMD! && [ -f ~/!_SP_DEST!/.venv/.libscript_lock_hash ]"
) else if exist "!_SP_REPO!\requirements.txt" (
    set "_ART_CMD=!_ART_CMD! && [ -f ~/!_SP_DEST!/.venv/.libscript_lock_hash ]"
)
for /d %%P in ("!_SP_REPO!\*") do (
    if exist "%%~fP\pyproject.toml" (
        set "_ART_CMD=!_ART_CMD! && [ -f ~/!_SP_DEST!/%%~nxP/.venv/.libscript_lock_hash ]"
    ) else if exist "%%~fP\uv.lock" (
        set "_ART_CMD=!_ART_CMD! && [ -f ~/!_SP_DEST!/%%~nxP/.venv/.libscript_lock_hash ]"
    ) else if exist "%%~fP\requirements.txt" (
        set "_ART_CMD=!_ART_CMD! && [ -f ~/!_SP_DEST!/%%~nxP/.venv/.libscript_lock_hash ]"
    )
)
set "_SKIP_UNCHANGED=0"
if "!DRY_RUN_MODE!"=="0" (
    if "!FORCE_REINSTALL!"=="1" (
        call "!CLI!" node exec "!NODE!" "!CTX!" "rm -f ~/.libscript_deployments/!_SP_DEST!.sha256" >nul 2>&1
    ) else if "!FORCE_REBUILD!"=="1" (
        call "!CLI!" node exec "!NODE!" "!CTX!" "rm -f ~/.libscript_deployments/!_SP_DEST!.sha256" >nul 2>&1
    )
)
if "!DRY_RUN_MODE!"=="0" if "!FORCE_REINSTALL!"=="0" if "!FORCE_REBUILD!"=="0" (
    call "!CLI!" node exec "!NODE!" "!CTX!" "[ -f ~/.libscript_deployments/!_SP_DEST!.sha256 ] && grep -qx '!_APP_HASH!' ~/.libscript_deployments/!_SP_DEST!.sha256 2>/dev/null && !_ART_CMD! && cd ~/!_SP_DEST! && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh health libscript.json && $HOME/libscript/_lib/orchestration/run_hooks.sh libscript.json health >/dev/null 2>&1" >nul 2>&1
    if not errorlevel 1 set "_SKIP_UNCHANGED=1"
)
if "!_SKIP_UNCHANGED!"=="1" (
    call :log "REUSE" "Application '!_SP_DEST!' checksum (!_APP_HASH!) unchanged and services/databases healthy; skipping file upload, install-deps, and rebuild."
) else (
    call :log "DEPLOY" "Deploying '!_SP_DEST!' ('!_SP_REPO!' -> '!_SP_DEST!', domain: '!_SP_DOMAIN!')..."
    call :run_with_auth_check "!CLI!" node deploy "!NODE!" "!CTX!" "!_SP_REPO!" "!_SP_DEST!"
    if errorlevel 1 exit /b 1

    if exist "!_SP_REPO!\.env" (
        call :log "CONFIG" "Uploading .env for !_SP_DEST!..."
        call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!_SP_REPO!\.env" "!_SP_DEST!/.env"
        if errorlevel 1 exit /b 1
        if "!DRY_RUN_MODE!"=="0" if exist "!_SP_REPO!\libscript.json" (
            for /f "tokens=1* delims==" %%A in ('jq -r --arg eq "=" "([(.env // {}), (.remote_env // {}), ((.services // .infrastructure.services) | if type == \"object\" then .[] elif type == \"array\" then .[] else empty end | (.env // .environment // {}))] | add // {}) | to_entries[] | {key: .key, def: (if (.value | type) == \"string\" then (.value | sub(\"^\\$\\{[A-Za-z0-9_]+:-\"; \"\") | sub(\"\\}$\"; \"\")) else \"\" end)} | select(.def | test(\"^/[^:]+:/[^:]+\")) | (.key + $eq + .def)" "!_SP_REPO!\libscript.json" 2^>nul') do (
                for /f "tokens=1 delims=:" %%F in ("%%B") do (
                    call "!CLI!" node exec "!NODE!" "!CTX!" "if [ -f ~/!_SP_DEST!/.env ] && grep -q '^%%A=' ~/!_SP_DEST!/.env && ! grep '^%%A=' ~/!_SP_DEST!/.env | grep -F -q '%%F'; then sed 's|^%%A=.*|%%A=%%B|' ~/!_SP_DEST!/.env > ~/!_SP_DEST!/.env.tmp && mv ~/!_SP_DEST!/.env.tmp ~/!_SP_DEST!/.env; fi" >nul 2>&1
                )
            )
        )
    )
    if exist "!_SP_REPO!\.env.secrets" (
        call :log "CONFIG" "Uploading .env.secrets for !_SP_DEST!..."
        call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!_SP_REPO!\.env.secrets" "!_SP_DEST!/.env.secrets"
        if errorlevel 1 exit /b 1
    )

    if "!SKIP_PREPARE!"=="0" if "!PREPARED_STORAGE!"=="0" (
        call :log "PREPARE" "Preparing persistent storage and daemon overrides on '!NODE!' via LibScript..."
        call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh prepare-storage libscript.json"
        if errorlevel 1 exit /b 1
        call :prepare_remote_jaeb_storage
        set "PREPARED_STORAGE=1"
    )

    call :log "DEPS" "Resolving dependencies, provisioning databases, running data upserts, and building bundles for '!_SP_DEST!'..."
    call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh install-deps libscript.json!_DEPS_FLAGS!"
    if errorlevel 1 exit /b 1

    call :log "DAEMON" "Registering and starting/restarting application daemons for '!_SP_DEST!'..."
    call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript LIBSCRIPT_FORCE_RESTART=1 LIBSCRIPT_APP_HASH='!_APP_HASH!' LIBSCRIPT_SKIP_DB_INIT=1 $HOME/libscript/libscript.sh start libscript.json --skip-db-init"
    if errorlevel 1 exit /b 1
    if "!DRY_RUN_MODE!"=="0" (
        call "!CLI!" node exec "!NODE!" "!CTX!" "mkdir -p ~/.libscript_deployments && printf '%s\n' '!_APP_HASH!' > ~/.libscript_deployments/!_SP_DEST!.sha256" >nul 2>&1
    )
)

if not "!_SP_DOMAIN!"=="" (
    call :ensure_remote_etc_hosts_domain "!_SP_DOMAIN!"
    if "!SKIP_INFRA!"=="0" (
        call :log "DNS" "Ensuring DNS A record '!_SP_DOMAIN!' -> !IP!..."
        call :run_with_auth_check "!CLI!" dns record create "!_SP_DOMAIN!" "!CTX!" "@" A "!IP!"
    )
)

call :log "ROUTES" "Updating reverse-proxy routes and reloading ingress for '!_SP_DEST!' (!NODE!)..."
call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo HOME=$HOME !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/_lib/_common/component_core.sh --synchronize-ingress libscript.json --reload && $HOME/libscript/_lib/_common/component_core.sh --warmup-ollama gemma:2b"
set "_ROUTE_RC=!ERRORLEVEL!"
if "!DRY_RUN_MODE!"=="0" (
    call "!CLI!" node exec "!NODE!" "!CTX!" "if id ollama >/dev/null 2>&1 && [ -d '!_DEPLOY_OL_MODELS!' ]; then sudo chown -R ollama:ollama '!_DEPLOY_OL_MODELS!' 2>/dev/null || true; sudo chmod 02775 '!_DEPLOY_OL_MODELS!' 2>/dev/null || true; sudo chmod -R u+rwX,g+rwXs,o+rX '!_DEPLOY_OL_MODELS!' 2>/dev/null || true; fi" >nul 2>&1
)
exit /b !_ROUTE_RC!

:: ## prepare_remote_jaeb_storage
:: Ensures the external read-only DuckDB dataset directory exists on the remote node and idempotently stages the local dataset with a symlink and read-only permissions when configured.
:prepare_remote_jaeb_storage
if not "!SKIP_PREPARE!"=="0" exit /b 0
if "!DRY_RUN_MODE!"=="1" exit /b 0
set "_EXT_SLUG=t1"
set "_EXT_SLUG=!_EXT_SLUG!d"
set "_EXT_BASE=!_DEPLOY_DATA_MOUNT!/!_EXT_SLUG!"
set "_EXT_VAR=T1"
set "_EXT_VAR=!_EXT_VAR!D_LOCAL_JAEB_DB"
set "_LOCAL_JAEB_DB="
for /f "delims=" %%V in ("!_EXT_VAR!") do set "_LOCAL_JAEB_DB=!%%V!"
call "!CLI!" node exec "!NODE!" "!CTX!" "if [ -d '!_DEPLOY_DATA_MOUNT!' ] || sudo mkdir -p '!_DEPLOY_DATA_MOUNT!' 2>/dev/null; then sudo mkdir -p !_EXT_BASE!/jaeb && sudo chown -R !ADMIN_USER!:!ADMIN_USER! !_EXT_BASE! 2>/dev/null || true; fi" >nul 2>&1
if not "!_LOCAL_JAEB_DB!"=="" if exist "!_LOCAL_JAEB_DB!" (
    for %%Z in ("!_LOCAL_JAEB_DB!") do set "_LOCAL_JAEB_SZ=%%~zZ"
    if not "!_LOCAL_JAEB_SZ!"=="0" (
        call "!CLI!" node exec "!NODE!" "!CTX!" "[ -s !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb ] && [ \"$(wc -c < !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb | tr -d '[:space:]')\" = '!_LOCAL_JAEB_SZ!' ]" >nul 2>&1
        if not errorlevel 1 (
            call :log "REUSE" "Remote Jaeb DuckDB '!_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb' already matches local size (!_LOCAL_JAEB_SZ! bytes)."
        ) else (
            call :log "STORAGE" "Uploading local Jaeb DuckDB '!_LOCAL_JAEB_DB!' (!_LOCAL_JAEB_SZ! bytes) to '!NODE!:!_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb'..."
            call "!CLI!" node exec "!NODE!" "!CTX!" "sudo mkdir -p !_EXT_BASE!/jaeb && sudo chown -R !ADMIN_USER!:!ADMIN_USER! !_EXT_BASE! && sudo chmod u+w !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb 2>/dev/null || true" >nul 2>&1
            call :run_with_auth_check "!CLI!" node upload "!NODE!" "!CTX!" "!_LOCAL_JAEB_DB!" "!_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb"
        )
    )
)
call "!CLI!" node exec "!NODE!" "!CTX!" "if [ -s !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb ]; then sudo ln -sf !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb !_EXT_BASE!/!_EXT_SLUG!.duckdb && sudo chown -h !ADMIN_USER!:!ADMIN_USER! !_EXT_BASE!/!_EXT_SLUG!.duckdb 2>/dev/null || true; sudo chown !ADMIN_USER!:!ADMIN_USER! !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb 2>/dev/null || true; sudo chmod a+r,u-w,g-w,o-w !_EXT_BASE!/jaeb/!_EXT_SLUG!.duckdb 2>/dev/null || true; fi" >nul 2>&1
exit /b 0

:: ## ensure_remote_etc_hosts_domain
:: Idempotently ensures /etc/hosts on the remote node maps 127.0.0.1 to the specified application domain.
:ensure_remote_etc_hosts_domain
set "_ERHD_DOM=%~1"
if "!_ERHD_DOM!"=="" exit /b 0
if "!_ERHD_DOM!"=="null" exit /b 0
if not "!DRY_RUN_MODE!"=="0" exit /b 0
set "_ERHD_HOSTS=%REMOTE_ETC_HOSTS%"
if "!_ERHD_HOSTS!"=="" set "_ERHD_HOSTS=/etc/hosts"
call "!CLI!" node exec "!NODE!" "!CTX!" "if ! grep -Eq '^[[:space:]]*127\.0\.0\.1[[:space:]].*(^|[[:space:]])!_ERHD_DOM!([[:space:]]|$)' '!_ERHD_HOSTS!' 2>/dev/null; then printf '127.0.0.1 %%s\n' '!_ERHD_DOM!' | sudo tee -a '!_ERHD_HOSTS!' >/dev/null; fi" >nul 2>&1
exit /b 0

:: ## verify_one_spec
:: Verifies DNS, health, and ingress for a single deployed application specification and records report state.
:verify_one_spec
call :parse_spec "%~1"
call :check_only_match "!_SP_DEST!" "!_SP_REPO!"
if "!_MATCH!"=="0" exit /b 0
set "_DNS_LABEL=http://!IP!"
if not "!_SP_DOMAIN!"=="" (
    set "_DNS_LABEL=https://!_SP_DOMAIN!"
    call :ensure_remote_etc_hosts_domain "!_SP_DOMAIN!"
    if "!SKIP_INFRA!"=="0" (
        call :log "DNS" "Ensuring DNS A record '!_SP_DOMAIN!' -> !IP!..."
        call :run_with_auth_check "!CLI!" dns record create "!_SP_DOMAIN!" "!CTX!" "@" A "!IP!"
    )
)
if "!SKIP_VERIFY!"=="1" (
    set /a REPORT_COUNT+=1
    set "REPORT_ROW_!REPORT_COUNT!=| !_SP_DEST! | ~/!_SP_DEST! | !_DNS_LABEL! | SKIPPED | SKIPPED |"
    exit /b 0
)
set "_PUB_ARG="
if not "!_SP_DOMAIN!"=="" set "_PUB_ARG= --verify-ingress --public-url=https://!_SP_DOMAIN!"
call :log "HEALTH" "Verifying '!_SP_DEST!' health and ingress (!NODE!)..."
call :run_with_auth_check "!CLI!" node exec "!NODE!" "!CTX!" "cd ~/!_SP_DEST! && sudo HOME=$HOME SERVICE_USER='!ADMIN_USER!' REMOTE_USER='!ADMIN_USER!' !_REMOTE_OLLAMA_ENV! REMOTE_HOME=$HOME LIBSCRIPT_HOME=$HOME/.libscript LIBSCRIPT_ROOT_DIR=$HOME/libscript $HOME/libscript/libscript.sh health libscript.json --remediate!_PUB_ARG!"
set "_V_RC=!ERRORLEVEL!"
set /a REPORT_COUNT+=1
if "!_V_RC!"=="0" (
    if not "!_SP_DOMAIN!"=="" (
        set "REPORT_ROW_!REPORT_COUNT!=| !_SP_DEST! | ~/!_SP_DEST! | !_DNS_LABEL! | PASS (200) | PASS (TLS) |"
    ) else (
        set "REPORT_ROW_!REPORT_COUNT!=| !_SP_DEST! | ~/!_SP_DEST! | !_DNS_LABEL! | PASS (200) | LOCAL |"
    )
) else (
    set "REPORT_ROW_!REPORT_COUNT!=| !_SP_DEST! | ~/!_SP_DEST! | !_DNS_LABEL! | FAIL | FAIL |"
)
exit /b !_V_RC!


:: ## validate_shared_node_manifests
:: Validates that multiple applications deployed to a shared node do not have colliding service names or ports.
:validate_shared_node_manifests
if "!MANIFEST_FILES!"=="" exit /b 0
set "_MF_CNT=0"
for %%F in (!MANIFEST_FILES!) do set /a _MF_CNT+=1
if !_MF_CNT! lss 2 exit /b 0
set "_DUP_PORTS="
for /f "delims=" %%P in ('jq -s -r "[ .[] | (.services | if type == \"object\" then [to_entries[].value.port? // empty] elif type == \"array\" then [.[].port? // empty] else [] end) | map(tostring) | unique | .[] ] | group_by(.) | map(select(length > 1) | .[0]) | join(\" \")" !MANIFEST_FILES! 2^>nul') do set "_DUP_PORTS=%%P"
if not "!_DUP_PORTS!"=="" (
    call :log "ERROR" "Shared-node service port collision detected across manifests on port^(s^): !_DUP_PORTS!"
    exit /b 1
)
set "_DUP_SVCS="
for /f "delims=" %%S in ('jq -s -r "[ .[] | (.services | if type == \"object\" then [to_entries[].key] elif type == \"array\" then [.[].name? // empty] else [] end) | unique | .[] ] | group_by(.) | map(select(length > 1) | .[0]) | join(\" \")" !MANIFEST_FILES! 2^>nul') do set "_DUP_SVCS=%%S"
if not "!_DUP_SVCS!"=="" (
    call :log "ERROR" "Shared-node service name collision detected across manifests: !_DUP_SVCS!"
    exit /b 1
)
exit /b 0

:: ## compute_app_checksum
:: Computes a deterministic digest of an application repository manifest, env files, git revision, diff content, and untracked files.
:compute_app_checksum
set "_CAC_DIR=%~1"
set "_CAC_GIT=nogit"
for /f "delims=" %%H in ('git -C "!_CAC_DIR!" rev-parse HEAD 2^>nul') do set "_CAC_GIT=%%H"
set "_CAC_TMP=%TEMP%\libscript_cac_%RANDOM%.txt"
if exist "!_CAC_TMP!" del /f /q "!_CAC_TMP!" >nul 2>&1
if not "!_CAC_GIT!"=="nogit" (
    git -C "!_CAC_DIR!" status --porcelain 2>nul | findstr /V /I /C:".nyc_output" /C:"docs/web" /C:"docs/api" /C:"site/" /C:".vitest" >> "!_CAC_TMP!" 2>nul
    git -C "!_CAC_DIR!" diff HEAD -- . ":(exclude).nyc_output" ":(exclude)**/.nyc_output/**" ":(exclude)docs/web" ":(exclude)docs/api" ":(exclude)site" ":(exclude).vitest*" >> "!_CAC_TMP!" 2>nul
    for /f "delims=" %%U in ('git -C "!_CAC_DIR!" ls-files --others --exclude-standard 2^>nul') do (
        echo "%%U" | findstr /I /C:".nyc_output" /C:"docs/web" /C:"docs/api" /C:"site/" /C:".vitest" >nul 2>&1
        if errorlevel 1 (
            if exist "!_CAC_DIR!\%%U" (
                for %%Z in ("!_CAC_DIR!\%%U") do echo %%U:%%~zZ:%%~tZ>> "!_CAC_TMP!"
            )
        )
    )
) else (
    for /r "!_CAC_DIR!" %%F in (*) do (
        echo "%%~fF" | findstr /I /C:"\.nyc_output\" /C:"\docs\web\" /C:"\docs\api\" /C:"\site\" /C:"\.vitest" >nul 2>&1
        if errorlevel 1 (
            echo %%~nxF:%%~zF:%%~tF>> "!_CAC_TMP!"
        )
    )
)
for %%E in ("!_CAC_DIR!\libscript.json" "!_CAC_DIR!\.env" "!_CAC_DIR!\.env.secrets" "!REPO_PATH!\libscript.json" "!_CAC_DIR!\package.json" "!_CAC_DIR!\package-lock.json" "!_CAC_DIR!\pyproject.toml" "!_CAC_DIR!\uv.lock" "!_CAC_DIR!\requirements*.txt" "!_CAC_DIR!\angular.json" "!_CAC_DIR!\vite.config.*") do (
    if exist "%%~fE" type "%%~fE" >> "!_CAC_TMP!" 2>nul
)
for /d %%S in ("!_CAC_DIR!\*") do (
    for %%L in ("%%~fS\package.json" "%%~fS\package-lock.json" "%%~fS\pyproject.toml" "%%~fS\uv.lock" "%%~fS\requirements*.txt" "%%~fS\angular.json" "%%~fS\vite.config.*") do (
        if exist "%%~fL" type "%%~fL" >> "!_CAC_TMP!" 2>nul
    )
    for /d %%T in ("%%~fS\*") do (
        for %%M in ("%%~fT\package.json" "%%~fT\package-lock.json" "%%~fT\pyproject.toml" "%%~fT\uv.lock" "%%~fT\requirements*.txt" "%%~fT\angular.json" "%%~fT\vite.config.*") do (
            if exist "%%~fM" type "%%~fM" >> "!_CAC_TMP!" 2>nul
        )
    )
)
set "_CAC_DIRTY=0"
if exist "!_CAC_TMP!" (
    for /f "skip=1 tokens=1" %%D in ('certutil -hashfile "!_CAC_TMP!" SHA256 2^>nul') do (
        if "!_CAC_DIRTY!"=="0" set "_CAC_DIRTY=%%D"
    )
    del /f /q "!_CAC_TMP!" >nul 2>&1
)
set "_APP_HASH=!_CAC_GIT!_!_CAC_DIRTY!"
exit /b 0
