@echo off
:: # gcs_ml.cmd
:: ## Overview
:: Applies `schemas/gcs-ml-storage.schema.json` on Windows: enforces TFRC same-region bucket checks,
:: emits checkpoint lifecycle rules, worker env exports, and GKE GCS FUSE CSI annotations.
:: ## Usage
:: traits\storage\gcs_ml.cmd <config.json> --out-dir=<dir> [--zone=<tpu_zone>] [--dry-run]

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
if exist "!d!\libscript.cmd" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
if exist "!d!\ROOT" ( set "LIBSCRIPT_ROOT_DIR=!d!" & exit /b 0 )
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" ( echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2 & exit /b 1 )
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found
set "CFG_FILE="
set "OUT_DIR="
set "ZONE_VAL=%TPU_ZONE%"
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
goto :parse_args

:: ## parse_args
:: Parses CLI flags for gcs_ml.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a:~0,10!"=="--out-dir=" ( set "OUT_DIR=!_a:~10!" & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--zone=" ( set "ZONE_VAL=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if "!CFG_FILE!"=="" set "CFG_FILE=!_a!"
shift
goto :parse_args

:: ## args_done
:: Validates TFRC bucket regionality and synthesizes GCS ML manifests.
:args_done
if not exist "!CFG_FILE!" ( echo [ERROR] Valid GCS ML config JSON required. >&2 & exit /b 1 )
if "!OUT_DIR!"=="" set "OUT_DIR=%TEMP%\libscript-gcs-ml"
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
if "!ZONE_VAL!"=="" (
    for /f "usebackq delims=" %%Z in (`jq -r "(if has(\"ml\") then .ml.gcs_storage else . end) | .zone // \"us-central2-b\"" "!CFG_FILE!"`) do set "ZONE_VAL=%%Z"
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_is_enabled
if not errorlevel 1 (
    for /f "usebackq delims=" %%B in (`jq -r "(if has(\"ml\") then .ml.gcs_storage else . end) | [(.datasets[]?.uri // empty),(.checkpoints.uri // empty),(.xla_compilation_cache.uri // empty)] | .[] | select(length>0)" "!CFG_FILE!"`) do (
        call "!LIBSCRIPT_ROOT_DIR!\_lib\ml-training\_common\tfrc_guard.cmd" :libscript_tfrc_verify_gcs_bucket "%%B" "!ZONE_VAL!"
        if errorlevel 1 exit /b !errorlevel!
    )
)

jq "(if has(\"ml\") then .ml.gcs_storage else . end) | {rule:[{action:{type:\"Delete\"},condition:{age:(.checkpoints.retention_days // 30)}}]}" "!CFG_FILE!" > "!OUT_DIR!\checkpoint-lifecycle.json"
jq -r "(if has(\"ml\") then .ml.gcs_storage else . end) | \"export JAX_COMPILATION_CACHE_DIR=\\\"\" + (.xla_compilation_cache.uri // \"\") + \"\\\"\"" "!CFG_FILE!" > "!OUT_DIR!\tpu-gcs-env.sh"
jq "(if has(\"ml\") then .ml.gcs_storage else . end) | {podAnnotations:{\"gke-gcsfuse/volumes\":\"true\"},csiVolumes:(.fuse_mounts // [])}" "!CFG_FILE!" > "!OUT_DIR!\gke-gcsfuse-csi-patch.json"
echo [OK] Synthesized 4-role GCS ML storage coordination at !OUT_DIR!
exit /b 0
