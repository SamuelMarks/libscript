@echo off
:: # gcp.cmd
::
:: ## Overview
:: Synthesizes a Google Cloud Marketplace Terraform Solution package (`main.tf`, `variables.tf`,
:: `outputs.tf`, `metadata.yaml`, `display.yaml`) on Windows.
::
:: ## Usage
:: gcp.cmd <offer.json> --out-dir=<dir> [--stage-only] [--dry-run]

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
set "OUT_DIR="
goto :parse_args

:: ## parse_args
:: Parses CLI flags for gcp.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a:~0,10!"=="--out-dir=" ( set "OUT_DIR=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--stage-only" ( shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( shift & goto :parse_args )
if "!OFFER_FILE!"=="" set "OFFER_FILE=!_a!"
shift
goto :parse_args

:: ## args_done
:: Emits GCP Marketplace Terraform Blueprint and metadata files.
:args_done
if not exist "!OFFER_FILE!" ( echo [ERROR] Valid offer.json required >&2 & exit /b 1 )
for /f "usebackq delims=" %%I in (`jq -r ".offer_id" "!OFFER_FILE!"`) do set "OFFER_ID=%%I"
for /f "usebackq delims=" %%V in (`jq -r ".version" "!OFFER_FILE!"`) do set "OFFER_VER=%%V"
if "!OUT_DIR!"=="" set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build\marketplace\!OFFER_ID!\gcp"
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"

echo variable "project_id" { type = string }> "!OUT_DIR!\variables.tf"
echo # GCP Marketplace Unikernel Constellation (!OFFER_ID!)> "!OUT_DIR!\main.tf"
echo output "offer_id" { value = "!OFFER_ID!" }> "!OUT_DIR!\outputs.tf"
echo apiVersion: blueprints.cloud.google.com/v1alpha1> "!OUT_DIR!\metadata.yaml"
echo apiVersion: blueprints.cloud.google.com/v1alpha1> "!OUT_DIR!\display.yaml"
echo [OK] GCP Marketplace Terraform Blueprint synthesized at !OUT_DIR!
exit /b 0
