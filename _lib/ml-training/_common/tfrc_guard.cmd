@echo off
:: # tfrc_guard.cmd
::
:: ## Overview
:: Enforces TPU Research Cloud (TFRC) $0.00 zero-cost policy guardrails, SKU/zone/TTL allowlists, same-region GCS checks, and pre/post-flight orphan resource audits on Windows.
::
:: ## Usage
:: call "%LIBSCRIPT_ROOT_DIR%\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_validate_request "<project>" "<zone>" "<sku>" "<tier>" "<count>"

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

set "TFRC_EX_CONFIG=78"

if "%~1"=="" exit /b 0
call %*
set "_tg_rc=%ERRORLEVEL%"
endlocal & (
    set "TFRC_CONFIG=%TFRC_CONFIG%"
    set "LIBSCRIPT_TFRC_CONFIG=%LIBSCRIPT_TFRC_CONFIG%"
    set "TFRC_STRICT=%TFRC_STRICT%"
    set "LIBSCRIPT_TFRC_STRICT=%LIBSCRIPT_TFRC_STRICT%"
    set "TFRC_STORAGE_MODE=%TFRC_STORAGE_MODE%"
    set "LIBSCRIPT_TFRC_STORAGE_MODE=%LIBSCRIPT_TFRC_STORAGE_MODE%"
    set "TFRC_EXPLICIT_GCS_BUCKET=%TFRC_EXPLICIT_GCS_BUCKET%"
    set "TFRC_MAX_TTL_MINUTES=%TFRC_MAX_TTL_MINUTES%"
    set "LIBSCRIPT_TFRC_MAX_TTL_MINUTES=%LIBSCRIPT_TFRC_MAX_TTL_MINUTES%"
    set "TFRC_SHM_MIN_FREE_GB=%TFRC_SHM_MIN_FREE_GB%"
    set "LIBSCRIPT_TFRC_SHM_MIN_FREE_GB=%LIBSCRIPT_TFRC_SHM_MIN_FREE_GB%"
    set "TPU_USE_QUEUED_RESOURCE=%TPU_USE_QUEUED_RESOURCE%"
    set "TPU_DATA_DISK_SIZE=%TPU_DATA_DISK_SIZE%"
    set "DISK_SIZE_GB=%DISK_SIZE_GB%"
    set "DISK_NAME=%DISK_NAME%"
    set "BUCKET_NAME=%BUCKET_NAME%"
    set "GCS_BUCKET=%GCS_BUCKET%"
    set "GCP_PROJECT_ID=%GCP_PROJECT_ID%"
    set "TFRC_REUSE_ACTIVE_NODE=%TFRC_REUSE_ACTIVE_NODE%"
    exit /b %_tg_rc%
)
:: wincheck disable=CMD3005

:: ## libscript_tfrc_is_enabled
:: Returns 0 if TFRC zero-cost enforcement is active in the current environment, 1 otherwise.
:libscript_tfrc_is_enabled
if "%TFRC_STRICT%"=="1" exit /b 0
if /i "%TFRC_STRICT%"=="true" exit /b 0
if "%LIBSCRIPT_TFRC_STRICT%"=="1" exit /b 0
if not "%TFRC_CONFIG%"=="" exit /b 0
if not "%LIBSCRIPT_TFRC_CONFIG%"=="" exit /b 0
exit /b 1

:: ## libscript_tfrc_derive_topology
:: Computes host and chip counts for a TPU accelerator SKU and slice count.
:libscript_tfrc_derive_topology
set "_tg_sku=%~1"
set "_tg_slices=%~2"
if "!_tg_slices!"=="" set "_tg_slices=1"
set /a "_tg_slices_n=_tg_slices" 2>nul
REM wincheck disable=CMD2003
if !_tg_slices_n! lss 1 set "_tg_slices_n=1"
for /f "tokens=1,2 delims=-" %%A in ("!_tg_sku!") do (
    set "_tg_gen=%%A"
    set "_tg_num=%%B"
)
if "!_tg_num!"=="" set "_tg_num=8"
set /a "_tg_chips=_tg_num" 2>nul
REM wincheck disable=CMD2003
if !_tg_chips! lss 1 set "_tg_chips=1"
set /a "_tg_hosts=(_tg_chips + 3) / 4"
if /i "!_tg_gen!"=="v2" (
    set /a "_tg_chips=_tg_num / 2"
    REM wincheck disable=CMD2003
    if !_tg_chips! lss 1 set "_tg_chips=1"
    set /a "_tg_hosts=(_tg_chips + 3) / 4"
)
if /i "!_tg_gen!"=="v3" (
    set /a "_tg_chips=_tg_num / 2"
    REM wincheck disable=CMD2003
    if !_tg_chips! lss 1 set "_tg_chips=1"
    set /a "_tg_hosts=(_tg_chips + 3) / 4"
)
if /i "!_tg_gen!"=="v4" (
    set /a "_tg_chips=_tg_num / 2"
    REM wincheck disable=CMD2003
    if !_tg_chips! lss 1 set "_tg_chips=1"
    set /a "_tg_hosts=(_tg_chips + 3) / 4"
)
if /i "!_tg_gen!"=="v5p" (
    set /a "_tg_chips=_tg_num / 2"
    REM wincheck disable=CMD2003
    if !_tg_chips! lss 1 set "_tg_chips=1"
    set /a "_tg_hosts=(_tg_chips + 3) / 4"
)
if /i "!_tg_gen!"=="v5litepod" set /a "_tg_hosts=(_tg_chips + 7) / 8"
if /i "!_tg_gen!"=="v5e" set /a "_tg_hosts=(_tg_chips + 7) / 8"
if /i "!_tg_gen!"=="v6e" set /a "_tg_hosts=(_tg_chips + 7) / 8"
set /a "_tg_total_hosts=_tg_hosts * _tg_slices_n"
set /a "_tg_total_chips=_tg_chips * _tg_slices_n"
exit /b 0

:: ## libscript_tfrc_require_config
:: Resolves TFRC_CONFIG explicitly and validates all top-level and per-grant schema fields via jq.
:libscript_tfrc_require_config
set "_tg_repo=%~1"
if "!_tg_repo!"=="" set "_tg_repo=%REPO_DIR%"
if "!_tg_repo!"=="" set "_tg_repo=%APP_DIR%"
set "_tg_cfg=%TFRC_CONFIG%"
if "!_tg_cfg!"=="" set "_tg_cfg=%LIBSCRIPT_TFRC_CONFIG%"
if "!_tg_cfg!"=="" (
    if not "!_tg_repo!"=="" if exist "!_tg_repo!\tfrc.policy.json" set "_tg_cfg=!_tg_repo!\tfrc.policy.json"
)
if "!_tg_cfg!"=="" if exist ".\tfrc.policy.json" set "_tg_cfg=.\tfrc.policy.json"
if "!_tg_cfg!"=="" (
    echo [TFRC-GUARD] [VIOLATION] Missing explicit TFRC policy file. Supply --tfrc-config=^<path^> or TFRC_CONFIG. 1>&2
    exit /b 78
)
if not exist "!_tg_cfg!" (
    echo [TFRC-GUARD] [VIOLATION] TFRC policy file not found at '!_tg_cfg!'. 1>&2
    exit /b 78
)
where jq >nul 2>&1
if errorlevel 1 (
    echo [TFRC-GUARD] [VIOLATION] jq is required to validate TFRC policy files. 1>&2
    exit /b 78
)
for %%F in ("!_tg_cfg!") do set "TFRC_CONFIG=%%~fF"
set "LIBSCRIPT_TFRC_CONFIG=!TFRC_CONFIG!"
jq -e "(.schema_version // \"\") == \"1.0\" and (((.gcp_project_id // \"\") | length) > 0) and (.strict_zero_cost | type) == \"boolean\" and (.strict_zero_cost == true) and (.grants | type) == \"array\" and ((.grants | length) > 0) and (([.grants[] | select((((.zone // \"\") | length) == 0) or (((.accelerator_types // []) | length) == 0) or (((.scheduling_tiers // []) | length) == 0) or ((.max_chips // 0) < 1) or ((.max_concurrent_nodes // 0) < 1))] | length) == 0)" "!TFRC_CONFIG!" >nul 2>&1
if errorlevel 1 (
    echo [TFRC-GUARD] [VIOLATION] Invalid TFRC policy schema in '!TFRC_CONFIG!'. 1>&2
    exit /b 78
)
set "TFRC_STRICT=1"
set "LIBSCRIPT_TFRC_STRICT=1"
if "!TFRC_MAX_TTL_MINUTES!"=="" if not "!LIBSCRIPT_TFRC_MAX_TTL_MINUTES!"=="" set "TFRC_MAX_TTL_MINUTES=!LIBSCRIPT_TFRC_MAX_TTL_MINUTES!"
if "!TFRC_SHM_MIN_FREE_GB!"=="" if not "!LIBSCRIPT_TFRC_SHM_MIN_FREE_GB!"=="" set "TFRC_SHM_MIN_FREE_GB=!LIBSCRIPT_TFRC_SHM_MIN_FREE_GB!"
if "!TFRC_STORAGE_MODE!"=="" if not "!LIBSCRIPT_TFRC_STORAGE_MODE!"=="" set "TFRC_STORAGE_MODE=!LIBSCRIPT_TFRC_STORAGE_MODE!"
if "!TFRC_MAX_TTL_MINUTES!"=="" for /f "usebackq delims=" %%V in (`jq -r ".max_ttl_minutes // 180" "!TFRC_CONFIG!"`) do set "TFRC_MAX_TTL_MINUTES=%%V"
if "!TFRC_SHM_MIN_FREE_GB!"=="" for /f "usebackq delims=" %%V in (`jq -r ".shm_min_free_gb // 32" "!TFRC_CONFIG!"`) do set "TFRC_SHM_MIN_FREE_GB=%%V"
if "!TFRC_STORAGE_MODE!"=="" for /f "usebackq delims=" %%V in (`jq -r ".storage_mode // \"ssh\"" "!TFRC_CONFIG!"`) do set "TFRC_STORAGE_MODE=%%V"
set "LIBSCRIPT_TFRC_MAX_TTL_MINUTES=!TFRC_MAX_TTL_MINUTES!"
set "LIBSCRIPT_TFRC_SHM_MIN_FREE_GB=!TFRC_SHM_MIN_FREE_GB!"
set "LIBSCRIPT_TFRC_STORAGE_MODE=!TFRC_STORAGE_MODE!"
exit /b 0

:: ## libscript_tfrc_enforce_zero_cost_env
:: Idempotently strips billable persistent disk and unverified GCS variables and blocks GKE/GPU/Artifact Registry targets.
:libscript_tfrc_enforce_zero_cost_env
set "TFRC_STRICT=1"
set "LIBSCRIPT_TFRC_STRICT=1"
if not "!TPU_NO_QUEUED_RESOURCE!"=="1" (
    if /i not "!TPU_USE_QUEUED_RESOURCE!"=="false" set "TPU_USE_QUEUED_RESOURCE=true"
)
if not "!TPU_DATA_DISK_SIZE!!DISK_SIZE_GB!"=="" (
    echo [TFRC-GUARD] Stripping persistent disk configuration ^(TPU_DATA_DISK_SIZE="!TPU_DATA_DISK_SIZE!", DISK_SIZE_GB="!DISK_SIZE_GB!"^) to enforce $0.00 TFRC compliance. 1>&2
)
set "TPU_DATA_DISK_SIZE="
set "DISK_SIZE_GB="
set "DISK_NAME="
if /i not "!TFRC_STORAGE_MODE!"=="same_region_gcs" if not "!TFRC_EXPLICIT_GCS_BUCKET!"=="1" (
    if not "!BUCKET_NAME!!GCS_BUCKET!"=="" (
        echo [TFRC-GUARD] Ignoring manifest GCS bucket ^(BUCKET_NAME="!BUCKET_NAME!", GCS_BUCKET="!GCS_BUCKET!"^) under default ssh storage_mode. 1>&2
    )
    set "BUCKET_NAME="
    set "GCS_BUCKET="
)
for %%T in (gke-xpk xpk gcp-gke-tpu-cluster gcp-gpu-vm gpu-vm gcp-filestore) do (
    if /i "!ML_TARGET!"=="%%T" (
        echo [TFRC-GUARD] [VIOLATION] Target '!ML_TARGET!' incurs non-TFRC GCP billing and is strictly forbidden in TFRC zero-cost mode. 1>&2
        exit /b 78
    )
)
if not "!DOCKER_IMAGE!"=="" (
    echo "!DOCKER_IMAGE!" | findstr /I ".pkg.dev/ gcr.io/" >nul 2>&1
    if not errorlevel 1 (
        set "_tg_forbid_ar=true"
        if not "!TFRC_CONFIG!"=="" if exist "!TFRC_CONFIG!" (
            for /f "usebackq delims=" %%A in (`jq -r "if .forbid_artifact_registry == false then \"false\" else \"true\" end" "!TFRC_CONFIG!" 2^>nul`) do set "_tg_forbid_ar=%%A"
        )
        if /i "!_tg_forbid_ar!"=="true" (
            echo [TFRC-GUARD] [VIOLATION] Artifact Registry / GCR image '!DOCKER_IMAGE!' is forbidden when forbid_artifact_registry=true. 1>&2
            exit /b 78
        )
    )
)
exit /b 0

:: ## libscript_tfrc_validate_request
:: Validates (project, zone, sku, scheduling_tier, count) against grants[], active gcloud project, and UTC expiration date.
:libscript_tfrc_validate_request
set "_tg_req_proj=%~1"
if "!_tg_req_proj!"=="" set "_tg_req_proj=%GCP_PROJECT_ID%"
set "_tg_req_zone=%~2"
if "!_tg_req_zone!"=="" set "_tg_req_zone=%TPU_ZONE%"
set "_tg_req_sku=%~3"
if "!_tg_req_sku!"=="" set "_tg_req_sku=%TPU_ACCELERATOR_TYPE%"
set "_tg_req_tier=%~4"
if "!_tg_req_tier!"=="" set "_tg_req_tier=%TPU_SCHEDULING_TYPE%"
if "!_tg_req_tier!"=="" set "_tg_req_tier=spot"
set "_tg_req_cnt=%~5"
if "!_tg_req_cnt!"=="" set "_tg_req_cnt=1"

call :libscript_tfrc_require_config
if errorlevel 1 exit /b !errorlevel!
call :libscript_tfrc_enforce_zero_cost_env
if errorlevel 1 exit /b !errorlevel!

for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "_tg_pol_proj=%%P"
if "!_tg_req_proj!"=="" (
    set "_tg_req_proj=!_tg_pol_proj!"
    set "GCP_PROJECT_ID=!_tg_pol_proj!"
)
if not "!_tg_req_proj!"=="!_tg_pol_proj!" (
    echo [TFRC-GUARD] [VIOLATION] Requested GCP_PROJECT_ID '!_tg_req_proj!' does not match TFRC policy '!_tg_pol_proj!'. 1>&2
    exit /b 78
)

set "_tg_is_dry=0"
if /i "!DRY_RUN!"=="true" set "_tg_is_dry=1"
if "!DRY_RUN!"=="1" set "_tg_is_dry=1"
if "!LIBSCRIPT_DRY_RUN!"=="1" set "_tg_is_dry=1"
if "!_tg_is_dry!"=="0" (
    where gcloud >nul 2>&1
    if not errorlevel 1 (
        set "_tg_act_proj="
        for /f "usebackq delims=" %%G in (`gcloud config get-value project 2^>nul`) do set "_tg_act_proj=%%G"
        if not "!_tg_act_proj!"=="" if /i not "!_tg_act_proj!"=="(unset)" if not "!_tg_act_proj!"=="!_tg_pol_proj!" (
            echo [TFRC-GUARD] [VIOLATION] Active gcloud project '!_tg_act_proj!' does not match TFRC policy '!_tg_pol_proj!'. 1>&2
            exit /b 78
        )
    )
)

if "!_tg_req_zone!"=="" (
    echo [TFRC-GUARD] [VIOLATION] TPU_ZONE must be explicitly specified and covered by TFRC grants[]. 1>&2
    exit /b 78
)
if "!_tg_req_sku!"=="" (
    echo [TFRC-GUARD] [VIOLATION] TPU_ACCELERATOR_TYPE must be explicitly specified and covered by TFRC grants[]. 1>&2
    exit /b 78
)

set "_tg_today=%TFRC_MOCK_UTC_DATE%"
if "!_tg_today!"=="" (
    for /f "usebackq delims=" %%D in (`jq -nr "now | strftime(\"%%Y-%%m-%%d\")"`) do set "_tg_today=%%D"
)
call :libscript_tfrc_derive_topology "!_tg_req_sku!" "!_tg_req_cnt!"

jq -e --arg z "!_tg_req_zone!" --arg s "!_tg_req_sku!" --arg t "!_tg_req_tier!" --arg d "!_tg_today!" --argjson h !_tg_total_hosts! --argjson c !_tg_total_chips! --argjson n !_tg_req_cnt! "[.grants[] | select(.zone == $z and ((.accelerator_types | index($s)) != null) and ((.scheduling_tiers | index($t)) != null) and (((.expires_on // \"\") == \"\") or (.expires_on >= $d)) and ($c <= .max_chips) and ($h <= (.max_hosts // 1)) and ($n <= (.max_concurrent_nodes // 1)))] | length > 0" "!TFRC_CONFIG!" >nul 2>&1
if errorlevel 1 (
    echo [TFRC-GUARD] [VIOLATION] Request ^(!_tg_req_zone!, !_tg_req_sku!, !_tg_req_tier!, hosts=!_tg_total_hosts!, chips=!_tg_total_chips!, nodes=!_tg_req_cnt!^) is not permitted by TFRC grants[]. 1>&2
    exit /b 78
)
echo [TFRC-GUARD] Verified grant: project=!_tg_pol_proj! zone=!_tg_req_zone! sku=!_tg_req_sku! tier=!_tg_req_tier! hosts=!_tg_total_hosts! chips=!_tg_total_chips! 1>&2
exit /b 0

:: ## libscript_tfrc_verify_gcs_bucket
:: Verifies an optional gs:// bucket is allowlisted (if configured), single-region, and matches TPU_ZONE's region.
:libscript_tfrc_verify_gcs_bucket
set "_tg_uri=%~1"
set "_tg_zone=%~2"
if "!_tg_uri!"=="" exit /b 0
call :libscript_tfrc_require_config
if errorlevel 1 exit /b !errorlevel!
set "_tg_clean=!_tg_uri:gs://=!"
for /f "tokens=1 delims=/" %%B in ("!_tg_clean!") do set "_tg_clean=%%B"
set "_tg_full=gs://!_tg_clean!"

jq -e --arg u "!_tg_full!" "((.allowed_gcs_buckets // []) | length == 0) or ((.allowed_gcs_buckets | index($u)) != null)" "!TFRC_CONFIG!" >nul 2>&1
if errorlevel 1 (
    echo [TFRC-GUARD] [VIOLATION] GCS bucket '!_tg_full!' is not in tfrc.policy.json allowed_gcs_buckets[]. 1>&2
    exit /b 78
)

set "_tg_bkt_proj=%GCP_PROJECT_ID%"
if "!_tg_bkt_proj!"=="" for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "_tg_bkt_proj=%%P"

set "_tg_exp_reg="
for /f "usebackq delims=" %%R in (`jq -nr --arg z "!_tg_zone!" "$z | sub(\"-[^-]+$\"; \"\") | ascii_upcase"`) do set "_tg_exp_reg=%%R"

set "_tg_tmp=%TEMP%\tfrc_bkt_%RANDOM%.json"
call gcloud storage buckets describe "!_tg_full!" --project="!_tg_bkt_proj!" --format=json > "!_tg_tmp!" 2>nul
if errorlevel 1 (
    del /f /q "!_tg_tmp!" >nul 2>&1
    echo [TFRC-GUARD] [VIOLATION] Unable to inspect GCS bucket '!_tg_full!' in project '!_tg_bkt_proj!'. 1>&2
    exit /b 78
)
jq -e --arg r "!_tg_exp_reg!" "((.locationType // .location_type // \"\") | ascii_downcase) == \"region\" and ((.location // \"\") | ascii_upcase) == $r" "!_tg_tmp!" >nul 2>&1
if errorlevel 1 (
    del /f /q "!_tg_tmp!" >nul 2>&1
    echo [TFRC-GUARD] [VIOLATION] GCS bucket '!_tg_full!' must have locationType='region' and location='!_tg_exp_reg!' matching zone '!_tg_zone!'. 1>&2
    exit /b 78
)
del /f /q "!_tg_tmp!" >nul 2>&1
set "TFRC_STORAGE_MODE=same_region_gcs"
set "LIBSCRIPT_TFRC_STORAGE_MODE=same_region_gcs"
set "TFRC_EXPLICIT_GCS_BUCKET=1"
echo [TFRC-GUARD] Verified same-region GCS bucket !_tg_full! ^(!_tg_exp_reg!^) 1>&2
exit /b 0

:: ## libscript_tfrc_preflight_audit
:: Audits active GKE clusters, reserved static IPs, orphaned persistent disks, and concurrent TPU limits prior to creation.
:libscript_tfrc_preflight_audit
set "_tg_proj=%~1"
if "!_tg_proj!"=="" set "_tg_proj=%GCP_PROJECT_ID%"
set "_tg_zone=%~2"
if "!_tg_zone!"=="" set "_tg_zone=%TPU_ZONE%"
set "_tg_name=%~3"
if "!_tg_name!"=="" set "_tg_name=%TPU_NAME%"
call :libscript_tfrc_require_config
if errorlevel 1 exit /b !errorlevel!
if "!_tg_proj!"=="" for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "_tg_proj=%%P"
set "TFRC_REUSE_ACTIVE_NODE=0"
if /i "!DRY_RUN!"=="true" exit /b 0
if "!DRY_RUN!"=="1" exit /b 0
if "!LIBSCRIPT_DRY_RUN!"=="1" exit /b 0
where gcloud >nul 2>&1
if errorlevel 1 exit /b 0

set "_tg_max_nodes=1"
for /f "usebackq delims=" %%M in (`jq -r --arg z "!_tg_zone!" "[.grants[] | select(.zone == $z) | .max_concurrent_nodes // 1] | max // 1" "!TFRC_CONFIG!"`) do set "_tg_max_nodes=%%M"

set "_tg_tmp=%TEMP%\tfrc_pre_%RANDOM%.json"
set "_tg_tmp_qr=%TEMP%\tfrc_pre_qr_%RANDOM%.json"

call gcloud container clusters list --project="!_tg_proj!" --format=json > "!_tg_tmp!" 2>nul
if not errorlevel 1 (
    jq -e "length == 0" "!_tg_tmp!" >nul 2>&1
    if errorlevel 1 (
        del /f /q "!_tg_tmp!" "!_tg_tmp_qr!" >nul 2>&1
        echo [TFRC-GUARD] [VIOLATION] Active GKE cluster detected in project '!_tg_proj!'. 1>&2
        exit /b 78
    )
)

call gcloud compute addresses list --project="!_tg_proj!" --format=json > "!_tg_tmp!" 2>nul
if not errorlevel 1 (
    jq -e "[.[] | select((.status // \"\") == \"RESERVED\")] | length == 0" "!_tg_tmp!" >nul 2>&1
    if errorlevel 1 (
        del /f /q "!_tg_tmp!" "!_tg_tmp_qr!" >nul 2>&1
        echo [TFRC-GUARD] [VIOLATION] Reserved static external IP address detected in project '!_tg_proj!'. 1>&2
        exit /b 78
    )
)

call gcloud compute disks list --filter="zone:(!_tg_zone!)" --project="!_tg_proj!" --format=json > "!_tg_tmp!" 2>nul
if not errorlevel 1 (
    jq -e "[.[] | select((((.users // []) | length) == 0) and ((.name // \"\") | test(\"libscript|tpu|ml-eval\")))] | length == 0" "!_tg_tmp!" >nul 2>&1
    if errorlevel 1 (
        del /f /q "!_tg_tmp!" "!_tg_tmp_qr!" >nul 2>&1
        echo [TFRC-GUARD] [VIOLATION] Orphaned persistent disk detected in '!_tg_zone!'. Delete unattached disks to preserve $0.00 TFRC spend. 1>&2
        exit /b 78
    )
)

echo [] > "!_tg_tmp!"
call gcloud compute tpus tpu-vm list --zone="!_tg_zone!" --project="!_tg_proj!" --format=json > "!_tg_tmp!" 2>nul
if not "!_tg_name!"=="" (
    jq -e --arg n "!_tg_name!" "[.[] | select((.name | split(\"/\") | last) == $n and (.state == \"READY\" or .state == \"ACTIVE\"))] | length > 0" "!_tg_tmp!" >nul 2>&1
    if not errorlevel 1 (
        del /f /q "!_tg_tmp!" "!_tg_tmp_qr!" >nul 2>&1
        set "TFRC_REUSE_ACTIVE_NODE=1"
        echo [TFRC-GUARD] Existing active TPU node "!_tg_name!" found in !_tg_zone!; marking reusable for idempotent re-entry. 1>&2
        exit /b 0
    )
)

echo [] > "!_tg_tmp_qr!"
call gcloud compute tpus queued-resources list --zone="!_tg_zone!" --project="!_tg_proj!" --format=json > "!_tg_tmp_qr!" 2>nul
if errorlevel 1 (
    call gcloud alpha compute tpus queued-resources list --zone="!_tg_zone!" --project="!_tg_proj!" --format=json > "!_tg_tmp_qr!" 2>nul
)

set "_tg_act_tpu=0"
set "_tg_act_qr=0"
for /f "usebackq delims=" %%C in (`jq -r "length" "!_tg_tmp!" 2^>nul`) do set "_tg_act_tpu=%%C"
for /f "usebackq delims=" %%Q in (`jq -r --arg n "!_tg_name!-qr" "[.[] | select((.name | split(\"/\") | last) != $n)] | length" "!_tg_tmp_qr!" 2^>nul`) do set "_tg_act_qr=%%Q"
del /f /q "!_tg_tmp!" "!_tg_tmp_qr!" >nul 2>&1

set /a "_tg_active=_tg_act_tpu"
REM wincheck disable=CMD2003
if !_tg_act_qr! gtr !_tg_active! set /a "_tg_active=_tg_act_qr"
set /a "_tg_next=_tg_active + 1"
REM wincheck disable=CMD2003
if !_tg_next! gtr !_tg_max_nodes! (
    echo [TFRC-GUARD] [VIOLATION] Zone '!_tg_zone!' already has !_tg_active! TPU node^(s^)/Queued Resource^(s^), exceeding max_concurrent_nodes=!_tg_max_nodes!. 1>&2
    exit /b 78
)
exit /b 0

:: ## libscript_tfrc_postflight_audit
:: Asserts zero surviving TPU VMs, Queued Resources, or persistent disks remain after teardown.
:libscript_tfrc_postflight_audit
set "_tg_proj=%~1"
if "!_tg_proj!"=="" set "_tg_proj=%GCP_PROJECT_ID%"
set "_tg_zone=%~2"
if "!_tg_zone!"=="" set "_tg_zone=%TPU_ZONE%"
set "_tg_name=%~3"
if "!_tg_name!"=="" set "_tg_name=%TPU_NAME%"
if "!_tg_proj!"=="" if not "!TFRC_CONFIG!"=="" if exist "!TFRC_CONFIG!" (
    for /f "usebackq delims=" %%P in (`jq -r ".gcp_project_id" "!TFRC_CONFIG!"`) do set "_tg_proj=%%P"
)
if /i "!DRY_RUN!"=="true" exit /b 0
if "!DRY_RUN!"=="1" exit /b 0
if "!LIBSCRIPT_DRY_RUN!"=="1" exit /b 0
where gcloud >nul 2>&1
if errorlevel 1 exit /b 0

set "_tg_tmp_tpu=%TEMP%\tfrc_post_tpu_%RANDOM%.json"
set "_tg_tmp_qr=%TEMP%\tfrc_post_qr_%RANDOM%.json"
set "_tg_tmp_dsk=%TEMP%\tfrc_post_dsk_%RANDOM%.json"
echo [] > "!_tg_tmp_tpu!"
echo [] > "!_tg_tmp_qr!"
echo [] > "!_tg_tmp_dsk!"

call gcloud compute tpus tpu-vm list --zone="!_tg_zone!" --project="!_tg_proj!" --format=json > "!_tg_tmp_tpu!" 2>nul
call gcloud compute tpus queued-resources list --zone="!_tg_zone!" --project="!_tg_proj!" --format=json > "!_tg_tmp_qr!" 2>nul
if errorlevel 1 (
    call gcloud alpha compute tpus queued-resources list --zone="!_tg_zone!" --project="!_tg_proj!" --format=json > "!_tg_tmp_qr!" 2>nul
)
call gcloud compute disks list --filter="zone:(!_tg_zone!)" --project="!_tg_proj!" --format=json > "!_tg_tmp_dsk!" 2>nul

set "_tg_rem_tpu=0"
set "_tg_rem_qr=0"
set "_tg_rem_dsk=0"
if not "!_tg_name!"=="" (
    for /f "usebackq delims=" %%C in (`jq -r --arg n "!_tg_name!" "[.[] | select((.name | split(\"/\") | last) == $n)] | length" "!_tg_tmp_tpu!" 2^>nul`) do set "_tg_rem_tpu=%%C"
    for /f "usebackq delims=" %%C in (`jq -r --arg n "!_tg_name!-qr" "[.[] | select((.name | split(\"/\") | last) == $n)] | length" "!_tg_tmp_qr!" 2^>nul`) do set "_tg_rem_qr=%%C"
    for /f "usebackq delims=" %%C in (`jq -r --arg n "!_tg_name!" "[.[] | select((.name // \"\") | contains($n))] | length" "!_tg_tmp_dsk!" 2^>nul`) do set "_tg_rem_dsk=%%C"
) else (
    for /f "usebackq delims=" %%C in (`jq -r "length" "!_tg_tmp_tpu!" 2^>nul`) do set "_tg_rem_tpu=%%C"
    for /f "usebackq delims=" %%C in (`jq -r "length" "!_tg_tmp_qr!" 2^>nul`) do set "_tg_rem_qr=%%C"
)
del /f /q "!_tg_tmp_tpu!" "!_tg_tmp_qr!" "!_tg_tmp_dsk!" >nul 2>&1

REM wincheck disable=CMD2003
if !_tg_rem_tpu! gtr 0 goto :postflight_fail
REM wincheck disable=CMD2003
if !_tg_rem_qr! gtr 0 goto :postflight_fail
REM wincheck disable=CMD2003
if !_tg_rem_dsk! gtr 0 goto :postflight_fail
echo [TFRC-GUARD] Post-flight audit passed: zero surviving TPU VMs, Queued Resources, or disks in !_tg_zone!. 1>&2
exit /b 0

:: ## postflight_fail
:: Emits emergency remediation gcloud commands and fails with exit code 1 when resources survive teardown.
:postflight_fail
echo [TFRC-GUARD] [POSTFLIGHT-FAIL] Surviving resources detected in !_tg_zone! ^(tpu_vm=!_tg_rem_tpu!, queued_resources=!_tg_rem_qr!, disks=!_tg_rem_dsk!^)^^! 1>&2
if not "!_tg_name!"=="" (
    echo [TFRC-GUARD] Emergency cleanup: gcloud compute tpus queued-resources delete "!_tg_name!-qr" --zone="!_tg_zone!" --project="!_tg_proj!" --force --quiet ^&^& gcloud compute tpus tpu-vm delete "!_tg_name!" --zone="!_tg_zone!" --project="!_tg_proj!" --quiet 1>&2
)
exit /b 1
