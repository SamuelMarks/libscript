@echo off
:: # publish.cmd
::
:: ## Overview
:: End-to-end multicloud marketplace orchestrator on Windows (`libscript.cmd publish-marketplace`)
:: executing compliance/SBOM verification, UEFI unikernel packaging, and AWS/Azure/GCP bundle synthesis.
::
:: ## Usage
:: publish.cmd <offer.json> [--clouds=aws,azure,gcp] [--out-dir=<dir>] [--stage-only] [--dry-run] [--allow-stub-sdk]

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

set "OFFER_FILE="
set "CLOUDS_CSV=aws,azure,gcp"
set "OUT_DIR="
set "STAGE_ONLY=0"
set "DRY_RUN=0"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"

:: ## parse_args
:: Parses CLI flags for publish.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,9!"=="--clouds=" ( set "CLOUDS_CSV=!_a:~9!" & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--out-dir=" ( set "OUT_DIR=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--stage-only" ( set "STAGE_ONLY=1" & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_args )
if /i "!_a!"=="--allow-stub-sdk" ( set "ALLOW_STUB=1" & shift & goto :parse_args )
if "!OFFER_FILE!"=="" set "OFFER_FILE=!_a!"
shift
goto :parse_args

:: ## show_help
:: Displays usage help for publish-marketplace.
:show_help
echo Usage: libscript.cmd publish-marketplace ^<offer.json^> [--clouds=aws,azure,gcp] [--out-dir=^<dir^>] [--stage-only] [--dry-run] [--allow-stub-sdk]
exit /b 0

:: ## args_done
:: Runs compliance check and dispatches AWS, Azure, and GCP marketplace drivers.
:args_done
if not exist "!OFFER_FILE!" ( echo [ERROR] Existing offer.json required >&2 & exit /b 1 )
for /f "usebackq delims=" %%I in (`jq -r ".offer_id" "!OFFER_FILE!"`) do set "OFFER_ID=%%I"
if "!OUT_DIR!"=="" set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build\marketplace\!OFFER_ID!"
if not exist "!OUT_DIR!\images" mkdir "!OUT_DIR!\images"

if exist "!OUT_DIR!\.publish_stamp" (
    echo [SKIP] Marketplace offer !OFFER_ID! already synthesized at !OUT_DIR!
    exit /b 0
)

set "STACK="
call "!SCRIPT_DIR!\verify_compliance.cmd" "!OFFER_FILE!" --sysroot-dir="!OUT_DIR!\images" --out-sbom="!OUT_DIR!\sbom.spdx.json"
if errorlevel 1 exit /b 1

for %%C in (!CLOUDS_CSV:,= !) do (
    set "STACK="
    if /i "%%C"=="aws" call "!SCRIPT_DIR!\aws.cmd" "!OFFER_FILE!" --out-dir="!OUT_DIR!\aws" --dry-run
    if /i "%%C"=="azure" call "!SCRIPT_DIR!\azure.cmd" "!OFFER_FILE!" --out-dir="!OUT_DIR!\azure" --dry-run
    if /i "%%C"=="gcp" call "!SCRIPT_DIR!\gcp.cmd" "!OFFER_FILE!" --out-dir="!OUT_DIR!\gcp" --dry-run
)
echo !CLOUDS_CSV!> "!OUT_DIR!\.publish_stamp"
echo [OK] Multicloud marketplace offer !OFFER_ID! staged at !OUT_DIR!
exit /b 0
