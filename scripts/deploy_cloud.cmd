@echo off
setlocal EnableDelayedExpansion

set "PROVIDER=%~1"
set "NODE=%~2"
set "RG=%~3"
set "LOC=%~4"
set "REPO_PATH=%~5"
if "!REPO_PATH!"=="" set "REPO_PATH=."
set "REMOTE_DEST=%~6"
if "!REMOTE_DEST!"=="" set "REMOTE_DEST=~/%NODE%"

if "!LOC!"=="" (
  echo Usage: deploy_cloud.bat ^<provider^> ^<node_name^> ^<rg_or_vpc_or_project^> ^<region_or_zone^> [local_repo_path] [remote_dest]
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Logging Configuration
:: -----------------------------------------------------------------------------
set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=!datetime:~0,14!"
set "LOG_FILE=!LOG_DIR!\provision-!TIMESTAMP!.log"

call :log "INIT" "Starting !PROVIDER! deployment for !NODE!..."
call :log "INIT" "Logging to !LOG_FILE!"

set "STATE_FILE=!REPO_PATH!\.deploy_state"
if not exist "!STATE_FILE!" type nul > "!STATE_FILE!"

call :record_state "PROVIDER" "!PROVIDER!"
call :record_state "NODE" "!NODE!"
call :record_state "RG" "!RG!"
call :record_state "REGION" "!LOC!"

set "CLI=%~dp0..\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
  call :log "ERROR" "Provider !PROVIDER! not supported."
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Read Configuration
:: -----------------------------------------------------------------------------
set "DOMAIN="
set "SECRETS_DIR="
set "OS_IMAGE="
set "SIZE="
set "DISK_GB="
set "PORTS=22 80 443"
set "STATE_BUCKET="
set "STATE_ENDPOINT="
set "STATE_PATHS="

if exist "!REPO_PATH!\libscript.json" (
  where jq >nul 2>&1
  if !errorlevel! equ 0 (
    for /f "delims=" %%I in ('jq -r ".domain // \"\"" "!REPO_PATH!\libscript.json"') do set "DOMAIN=%%I"
    for /f "delims=" %%I in ('jq -r ".secrets_dir // \"\"" "!REPO_PATH!\libscript.json"') do set "SECRETS_DIR=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.os // \"\"" "!REPO_PATH!\libscript.json"') do set "OS_IMAGE=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.size // \"\"" "!REPO_PATH!\libscript.json"') do set "SIZE=%%I"
    for /f "delims=" %%I in ('jq -r ".infrastructure.node.disk_gb // \"\"" "!REPO_PATH!\libscript.json"') do set "DISK_GB=%%I"
    for /f "delims=" %%I in ('jq -r "if .infrastructure.network.ports then (.infrastructure.network.ports | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "PORTS=%%I"
    if "!PORTS!"=="" set "PORTS=22 80 443"
    for /f "delims=" %%I in ('jq -r ".state.bucket // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_BUCKET=%%I"
    for /f "delims=" %%I in ('jq -r ".state.endpoint // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_ENDPOINT=%%I"
    for /f "delims=" %%I in ('jq -r "if .state.paths then (.state.paths | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "STATE_PATHS=%%I"
  )
)

if "!OS_IMAGE!"=="" (
  if "!PROVIDER!"=="azure" set "OS_IMAGE=Ubuntu2204"
  if "!PROVIDER!"=="aws" set "OS_IMAGE=ami-0c7217cdde317cfec"
  if "!PROVIDER!"=="gcp" set "OS_IMAGE=ubuntu-2204-lts"
)
if "!SIZE!"=="" (
  if "!PROVIDER!"=="azure" set "SIZE=Standard_B2s"
  if "!PROVIDER!"=="aws" set "SIZE=t3.medium"
  if "!PROVIDER!"=="gcp" set "SIZE=e2-medium"
) else (
  echo !SIZE! | findstr /b "Standard_D" >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="aws" set "SIZE=t3.xlarge"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-standard-4"
  )
  echo !SIZE! | findstr /b "Standard_B" >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="aws" set "SIZE=t3.medium"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-medium"
  )
  echo !SIZE! | findstr /b "t3." >nul
  if not errorlevel 1 (
    if "!PROVIDER!"=="azure" set "SIZE=Standard_D4s_v3"
    if "!PROVIDER!"=="gcp" set "SIZE=e2-standard-4"
  )
)

call :log "INFRA" "Provisioning Network and Compute..."

if "!PROVIDER!"=="azure" (
  call :retry az group create --name "!RG!" --location "!LOC!"
  call :record_state "AZURE_RG" "!RG!"
  call :retry "!CLI!" network create "!NODE!-vnet" "!RG!" --location "!LOC!"
  call :record_state "AZURE_VNET" "!NODE!-vnet"
  call :retry "!CLI!" firewall create "!NODE!-nsg" "!RG!" "!PORTS!" --location "!LOC!"
  call :record_state "AZURE_NSG" "!NODE!-nsg"
  set "NODE_ARGS=--size !SIZE! --vnet-name !NODE!-vnet --nsg !NODE!-nsg"
  if not "!DISK_GB!"=="" set "NODE_ARGS=!NODE_ARGS! --os-disk-size-gb !DISK_GB!"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!RG!" !NODE_ARGS!
  call :record_state "AZURE_NODE" "!NODE!"
)

if "!PROVIDER!"=="aws" (
  set "AWS_DEFAULT_REGION=!LOC!"
  for /f "tokens=*" %%i in ('call "!CLI!" network create "!NODE!-vpc"') do set "VPC_ID=%%i"
  call :record_state "AWS_VPC" "!VPC_ID!"
  for /f "tokens=*" %%i in ('call "!CLI!" firewall create "!NODE!-sg" "!NODE!-vpc" "!PORTS!"') do set "SG_ID=%%i"
  call :record_state "AWS_SG" "!SG_ID!"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!NODE!-vpc" "!SIZE!"
  call :record_state "AWS_NODE" "!NODE!"
)

if "!PROVIDER!"=="gcp" (
  set "GCP_ZONE=!LOC!"
  call :retry "!CLI!" network create "!NODE!-vpc" "10.0.0.0/16"
  call :record_state "GCP_VPC" "!NODE!-vpc"
  call :retry "!CLI!" firewall create "!NODE!-fw" "!NODE!-vpc" "!PORTS!"
  call :record_state "GCP_FW" "!NODE!-fw"
  call :retry "!CLI!" node create "!NODE!" "!OS_IMAGE!" "!RG!" --network "!NODE!-vpc!" --machine-type "!SIZE!"
  call :record_state "GCP_NODE" "!NODE!"
)

set "CTX=!RG!"
if "!PROVIDER!"=="aws" set "CTX=!LOC!"
if "!PROVIDER!"=="gcp" set "CTX=!LOC!"

:: -----------------------------------------------------------------------------
:: Wait for SSH / WinRM
:: -----------------------------------------------------------------------------
call :log "HEALTH" "Waiting for SSH/WinRM readiness on node !NODE!..."
set "ATTEMPT=1"
set "MAX_ATTEMPTS=30"
:SSH_LOOP
call "!CLI!" node exec "!NODE!" "!CTX!" "echo SSH_READY" >nul 2>&1
if %errorlevel% equ 0 (
  call :log "HEALTH" "SSH/WinRM is ready."
  goto :SSH_READY
)
if !ATTEMPT! geq !MAX_ATTEMPTS! (
  call :log "ERROR" "Node failed to become ready after !MAX_ATTEMPTS! attempts."
  exit /b 1
)
call :log "HEALTH" "Not ready (attempt !ATTEMPT!/!MAX_ATTEMPTS!). Waiting 10s..."
timeout /t 10 /nobreak >nul
set /a ATTEMPT+=1
goto :SSH_LOOP

:SSH_READY

:: -----------------------------------------------------------------------------
:: Sync and Deploy
:: -----------------------------------------------------------------------------
call :log "SYNC" "Syncing LibScript..."
call :retry "!CLI!" node sync "!NODE!" "!CTX!"

call :log "SYNC" "Deploying Repository..."
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "mkdir -p !REMOTE_DEST!"
where rsync >nul 2>&1
if %errorlevel% equ 0 (
  call :log "SYNC" "Using rsync..."
  call :retry "!CLI!" node deploy "!NODE!" "!CTX!" "!REPO_PATH!" "!REMOTE_DEST!"
) else (
  call :log "SYNC" "Using scp/winrm fallback..."
  call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!" "!REMOTE_DEST!"
)

if not "!SECRETS_DIR!"=="" if exist "!REPO_PATH!\!SECRETS_DIR!" (
  call :log "SECRETS" "Deploying Secrets out-of-band via node scp (bypassing gitignore)..."
  call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!\!SECRETS_DIR!" "!REMOTE_DEST!/!SECRETS_DIR!"
)

if not "!STATE_PATHS!"=="" (
  for %%P in (!STATE_PATHS!) do (
    if not "!STATE_BUCKET!"=="" (
      call :log "STATE" "Restoring %%P from object storage !STATE_BUCKET!..."
      if "!STATE_BUCKET:~0,5!"=="s3://" (
        set "S3_ARGS="
        if not "!STATE_ENDPOINT!"=="" set "S3_ARGS=--endpoint-url !STATE_ENDPOINT!"
        aws s3 cp !S3_ARGS! "!STATE_BUCKET!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,5!"=="gs://" (
        gcloud storage cp "!STATE_BUCKET!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,8!"=="azure://" (
        for /f "tokens=3 delims=/" %%C in ("!STATE_BUCKET!") do set "CONTAINER=%%C"
        az storage blob download --container-name "!CONTAINER!" --name "%%P" --file "!REPO_PATH!\%%P" --auth-mode login >> "!LOG_FILE!" 2>&1
      )
    )
    if exist "!REPO_PATH!\%%P" (
      call :log "STATE" "Deploying state %%P to node..."
      call :retry "!CLI!" node scp "!NODE!" "!CTX!" "!REPO_PATH!\%%P" "!REMOTE_DEST!/%%P"
    )
  )
)

if not "!DOMAIN!"=="" (
  call :log "DNS" "Mapping DNS for !DOMAIN!..."
  if "!PROVIDER!"=="azure" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call :retry "!CLI!" dns map-node "!NODE!" "!RG!" "!DOMAIN!" "!ZONE_NAME!" "!ZONE_NAME!-rg"
  ) else if "!PROVIDER!"=="aws" (
    if "!AWS_ZONE_ID!"=="" (
      for /f "tokens=*" %%i in ('aws route53 list-hosted-zones-by-name --dns-name "!DOMAIN!" --query "HostedZones[0].Id" --output text 2^>nul') do set "RAW_ID=%%i"
      if not "!RAW_ID!"=="None" (
        for %%a in ("!RAW_ID:/=" "!") do set "AWS_ZONE_ID=%%~a"
      )
    )
    if not "!AWS_ZONE_ID!"=="" (
      call :retry "!CLI!" dns map-node "!NODE!" "!DOMAIN!" "!AWS_ZONE_ID!"
    )
  ) else if "!PROVIDER!"=="gcp" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call :retry "!CLI!" dns map-node "!NODE!" "!LOC!" "!DOMAIN!" "!ZONE_NAME!"
  )
)

call :log "START" "Installing Dependencies and Starting..."
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh install-deps"
call :retry "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh start"

:: -----------------------------------------------------------------------------
:: Wait for Health
:: -----------------------------------------------------------------------------
call :log "HEALTH" "Polling application health (via libscript health)..."
set "ATTEMPT=1"
set "MAX_ATTEMPTS=12"
:HEALTH_LOOP
call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh health" >nul 2>&1
if %errorlevel% equ 0 (
  call :log "HEALTH" "Application stack is healthy."
  goto :HEALTH_READY
)
if !ATTEMPT! geq !MAX_ATTEMPTS! (
  call :log "WARNING" "Application health check failed or timed out. Check logs."
  goto :HEALTH_READY
)
call :log "HEALTH" "Application not ready (attempt !ATTEMPT!/!MAX_ATTEMPTS!). Waiting 10s..."
timeout /t 10 /nobreak >nul
set /a ATTEMPT+=1
goto :HEALTH_LOOP

:HEALTH_READY

call :log "DONE" "Deployment complete. View logs at !LOG_FILE!"
exit /b 0

:: -----------------------------------------------------------------------------
:: Functions
:: -----------------------------------------------------------------------------
:log
echo [%~1] %~2
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
exit /b 0

:record_state
echo %~1=%~2 >> "!STATE_FILE!"
call :log "STATE" "Recorded %~1=%~2"
exit /b 0

:retry
set "RETRY_ATTEMPT=1"
set "RETRY_MAX=5"
set "RETRY_WAIT=5"
:RETRY_LOOP
call :log "RETRY" "Attempt !RETRY_ATTEMPT! of !RETRY_MAX!: %*"
call %* >> "!LOG_FILE!" 2>&1
if %errorlevel% equ 0 (
  call :log "RETRY" "Command succeeded."
  exit /b 0
)
if !RETRY_ATTEMPT! geq !RETRY_MAX! (
  call :log "ERROR" "Command failed after !RETRY_MAX! attempts: %*"
  exit /b 1
)
call :log "RETRY" "Command failed (exit !errorlevel!). Waiting !RETRY_WAIT!s..."
timeout /t !RETRY_WAIT! /nobreak >nul
set /a RETRY_ATTEMPT+=1
set /a RETRY_WAIT*=2
goto :RETRY_LOOP
