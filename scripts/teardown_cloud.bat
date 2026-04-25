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
  echo Usage: teardown_cloud.bat ^<provider^> ^<node_name^> ^<rg_or_vpc_or_project^> ^<region_or_zone^> [local_repo_path] [remote_dest]
  exit /b 1
)

:: -----------------------------------------------------------------------------
:: Logging Configuration
:: -----------------------------------------------------------------------------
set "LOG_DIR=!REPO_PATH!\logs"
if not exist "!LOG_DIR!" mkdir "!LOG_DIR!"
for /f "tokens=2 delims==" %%I in ('wmic os get localdatetime /value') do set datetime=%%I
set "TIMESTAMP=!datetime:~0,14!"
set "LOG_FILE=!LOG_DIR!\teardown-!TIMESTAMP!.log"

call :log "INIT" "Starting !PROVIDER! teardown for !NODE!..."

set "STATE_FILE=!REPO_PATH!\.deploy_state"

set "DOMAIN="
set "STATE_BUCKET="
set "STATE_ENDPOINT="
set "STATE_PATHS="

if exist "!REPO_PATH!\libscript.json" (
  where jq >nul 2>&1
  if !errorlevel! equ 0 (
    for /f "delims=" %%I in ('jq -r ".domain // \"\"" "!REPO_PATH!\libscript.json"') do set "DOMAIN=%%I"
    for /f "delims=" %%I in ('jq -r ".state.bucket // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_BUCKET=%%I"
    for /f "delims=" %%I in ('jq -r ".state.endpoint // \"\"" "!REPO_PATH!\libscript.json"') do set "STATE_ENDPOINT=%%I"
    for /f "delims=" %%I in ('jq -r "if .state.paths then (.state.paths | join(\" \")) else \"\" end" "!REPO_PATH!\libscript.json"') do set "STATE_PATHS=%%I"
  )
)

set "CLI=%~dp0..\_lib\cloud-providers\!PROVIDER!\cli.cmd"
if not exist "!CLI!" (
  call :log "ERROR" "Provider !PROVIDER! not supported."
  exit /b 1
)

set "CTX=!RG!"
if "!PROVIDER!"=="aws" set "CTX=!LOC!"
if "!PROVIDER!"=="gcp" set "CTX=!LOC!"

call :log "STOP" "Stopping remote stack..."
call "!CLI!" node exec "!NODE!" "!CTX!" "cd !REMOTE_DEST! && sudo ~/libscript/libscript.sh stop" >> "!LOG_FILE!" 2>&1

if not "!STATE_PATHS!"=="" (
  for %%P in (!STATE_PATHS!) do (
    call :log "SYNC" "Syncing %%P from node to prevent data loss..."
    call "!CLI!" node scp-from "!NODE!" "!CTX!" "!REMOTE_DEST!/%%P" "!REPO_PATH!\%%P" >> "!LOG_FILE!" 2>&1

    if not "!STATE_BUCKET!"=="" if exist "!REPO_PATH!\%%P" (
      call :log "STATE" "Backing up %%P to object storage !STATE_BUCKET!..."
      if "!STATE_BUCKET:~0,5!"=="s3://" (
        set "S3_ARGS="
        if not "!STATE_ENDPOINT!"=="" set "S3_ARGS=--endpoint-url !STATE_ENDPOINT!"
        aws s3 cp !S3_ARGS! "!REPO_PATH!\%%P" "!STATE_BUCKET!/%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,5!"=="gs://" (
        gcloud storage cp "!REPO_PATH!\%%P" "!STATE_BUCKET!/%%P" >> "!LOG_FILE!" 2>&1
      ) else if "!STATE_BUCKET:~0,8!"=="azure://" (
        for /f "tokens=3 delims=/" %%C in ("!STATE_BUCKET!") do set "CONTAINER=%%C"
        az storage blob upload --container-name "!CONTAINER!" --name "%%P" --file "!REPO_PATH!\%%P" --auth-mode login --overwrite >> "!LOG_FILE!" 2>&1
      )
    )
  )
)

if not "!DOMAIN!"=="" (
  call :log "DNS" "Unmapping DNS..."
  if "!PROVIDER!"=="azure" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call "!CLI!" dns unmap-node "!NODE!" "!RG!" "!DOMAIN!" "!ZONE_NAME!" "!ZONE_NAME!-rg" >> "!LOG_FILE!" 2>&1
  ) else if "!PROVIDER!"=="aws" (
    if "!AWS_ZONE_ID!"=="" (
      for /f "tokens=*" %%i in ('aws route53 list-hosted-zones-by-name --dns-name "!DOMAIN!" --query "HostedZones[0].Id" --output text 2^>nul') do set "RAW_ID=%%i"
      if not "!RAW_ID!"=="None" (
        for %%a in ("!RAW_ID:/=" "!") do set "AWS_ZONE_ID=%%~a"
      )
    )
    if not "!AWS_ZONE_ID!"=="" (
      call "!CLI!" dns unmap-node "!NODE!" "!DOMAIN!" "!AWS_ZONE_ID!" >> "!LOG_FILE!" 2>&1
    )
  ) else if "!PROVIDER!"=="gcp" (
    for %%a in ("!DOMAIN:.*=!") do set "ZONE_NAME=%%~a"
    call "!CLI!" dns unmap-node "!NODE!" "!LOC!" "!DOMAIN!" "!ZONE_NAME!" >> "!LOG_FILE!" 2>&1
  )
)

call :log "INFRA" "Deleting Node..."
call "!CLI!" node delete "!NODE!" "!CTX!" >> "!LOG_FILE!" 2>&1

call :log "INFRA" "Deleting Firewall..."
if "!PROVIDER!"=="azure" (
  call "!CLI!" firewall delete "!NODE!-nsg!" "!RG!" >> "!LOG_FILE!" 2>&1
) else if "!PROVIDER!"=="aws" (
  set "SG_ID="
  if exist "!STATE_FILE!" (
    for /f "tokens=2 delims==" %%i in ('findstr "^AWS_SG=" "!STATE_FILE!"') do set "SG_ID=%%i"
  )
  if not "!SG_ID!"=="" (
    aws ec2 delete-security-group --group-id "!SG_ID!" >> "!LOG_FILE!" 2>&1
  )
) else if "!PROVIDER!"=="gcp" (
  call "!CLI!" firewall delete "!NODE!-fw" >> "!LOG_FILE!" 2>&1
)

call :log "INFRA" "Deleting Network..."
if "!PROVIDER!"=="azure" (
  call "!CLI!" network delete "!NODE!-vnet" "!RG!" >> "!LOG_FILE!" 2>&1
) else if "!PROVIDER!"=="aws" (
  set "VPC_ID="
  if exist "!STATE_FILE!" (
    for /f "tokens=2 delims==" %%i in ('findstr "^AWS_VPC=" "!STATE_FILE!"') do set "VPC_ID=%%i"
  )
  if not "!VPC_ID!"=="" (
    aws ec2 delete-vpc --vpc-id "!VPC_ID!" >> "!LOG_FILE!" 2>&1
  ) else (
    call "!CLI!" network delete "!NODE!-vpc" >> "!LOG_FILE!" 2>&1
  )
) else if "!PROVIDER!"=="gcp" (
  call "!CLI!" network delete "!NODE!-vpc" >> "!LOG_FILE!" 2>&1
)

if exist "!STATE_FILE!" (
  call :log "STATE" "Cleaning up !STATE_FILE!"
  del "!STATE_FILE!"
)

call :log "DONE" "Teardown complete."
exit /b 0

:: -----------------------------------------------------------------------------
:: Functions
:: -----------------------------------------------------------------------------
:log
echo [%~1] %~2
echo [%DATE% %TIME%] [%~1] %~2 >> "!LOG_FILE!"
exit /b 0
