@echo off
:: # aws.cmd
::
:: ## Overview
:: Synthesizes a multi-unikernel AWS CloudFormation deployment template and AWS Marketplace Catalog
:: API `StartChangeSet` payload on Windows.
::
:: ## Usage
:: aws.cmd <offer.json> --out-dir=<dir> [--stage-only] [--dry-run]

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
set "STAGE_ONLY=0"
set "DRY_RUN=0"

:: ## parse_args
:: Parses CLI flags for aws.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a:~0,10!"=="--out-dir=" ( set "OUT_DIR=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--stage-only" ( set "STAGE_ONLY=1" & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if "!OFFER_FILE!"=="" set "OFFER_FILE=!_a!"
shift
goto :parse_args

:: ## args_done
:: Generates CloudFormation and AWS Marketplace ChangeSet JSON files.
:args_done
if not exist "!OFFER_FILE!" ( echo [ERROR] Valid offer.json required >&2 & exit /b 1 )
for /f "usebackq delims=" %%I in (`jq -r ".offer_id" "!OFFER_FILE!"`) do set "OFFER_ID=%%I"
if "!OUT_DIR!"=="" set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build\marketplace\!OFFER_ID!\aws"
if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"

jq "{AWSTemplateFormatVersion:\"2010-09-09\",Description:(.product_title + \" \" + .version),Resources:{}}" "!OFFER_FILE!" > "!OUT_DIR!\cloudformation.template.json"
jq "{Catalog:\"AWSMarketplace\",ChangeSetName:(\"libscript-\" + .offer_id),ChangeSet:[{ChangeType:\"UpdateInformation\",Entity:{Type:\"CloudFormationProduct@1.0\",Identifier:.offer_id}}]}" "!OFFER_FILE!" > "!OUT_DIR!\marketplace-changeset.json"
echo [OK] AWS Marketplace CloudFormation ^& Catalog ChangeSet synthesized at !OUT_DIR!
exit /b 0
