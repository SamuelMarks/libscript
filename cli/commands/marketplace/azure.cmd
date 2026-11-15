@echo off
:: # azure.cmd
::
:: ## Overview
:: Synthesizes an Azure Marketplace Managed Application bundle (`mainTemplate.json`,
:: `createUiDefinition.json`, `viewDefinition.json`, `partner-center-offer.json`) on Windows.
::
:: ## Usage
:: azure.cmd <offer.json> --out-dir=<dir> [--stage-only] [--dry-run]

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

:: ## parse_args
:: Parses CLI flags for azure.cmd.
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
:: Generates ARM Managed Application files and Partner Center offer descriptor.
:args_done
if not exist "!OFFER_FILE!" ( echo [ERROR] Valid offer.json required >&2 & exit /b 1 )
for /f "usebackq delims=" %%I in (`jq -r ".offer_id" "!OFFER_FILE!"`) do set "OFFER_ID=%%I"
if "!OUT_DIR!"=="" set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build\marketplace\!OFFER_ID!\azure"
if not exist "!OUT_DIR!\pkg" mkdir "!OUT_DIR!\pkg"

jq "{\"$schema\":\"https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#\",contentVersion:\"1.0.0.0\",resources:[]}" "!OFFER_FILE!" > "!OUT_DIR!\pkg\mainTemplate.json"
jq "{handler:\"Microsoft.Azure.CreateUIDef\",version:\"0.1.2-preview\"}" "!OFFER_FILE!" > "!OUT_DIR!\pkg\createUiDefinition.json"
echo {"contentVersion":"0.0.0.1","views":[]}> "!OUT_DIR!\pkg\viewDefinition.json"
jq "{resourceType:\"AzureApplication\",id:.offer_id,version:.version}" "!OFFER_FILE!" > "!OUT_DIR!\partner-center-offer.json"
echo [OK] Azure Marketplace Managed Application bundle synthesized at !OUT_DIR!
exit /b 0
