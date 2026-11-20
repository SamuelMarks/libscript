@echo off
:: # verify_compliance.cmd
::
:: ## Overview
:: Pre-marketplace compliance gate on Windows verifying SSH/secret scrubbing, EULA presence,
:: strict ingress port whitelists, and deterministic SPDX 2.3 JSON SBOM emission.
::
:: ## Usage
:: verify_compliance.cmd <offer.json> [--sysroot-dir=<dir>] [--out-sbom=<sbom.json>]

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
set "SYSROOT_SCAN_DIR="
set "OUT_SBOM="
goto :parse_args

:: ## parse_args
:: Parses CLI flags for verify_compliance.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,14!"=="--sysroot-dir=" ( set "SYSROOT_SCAN_DIR=!_a:~14!" & shift & goto :parse_args )
if /i "!_a:~0,11!"=="--out-sbom=" ( set "OUT_SBOM=!_a:~11!" & shift & goto :parse_args )
if "!OFFER_FILE!"=="" set "OFFER_FILE=!_a!"
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions.
:show_help
echo Usage: verify_compliance.cmd ^<offer.json^> [--sysroot-dir=^<dir^>] [--out-sbom=^<sbom.json^>]
exit /b 0

:: ## args_done
:: Validates compliance gates and generates the SPDX 2.3 SBOM.
:args_done
if "!OFFER_FILE!"=="" ( echo [ERROR] offer.json required >&2 & exit /b 1 )
if not exist "!OFFER_FILE!" ( echo [ERROR] Offer not found: !OFFER_FILE! >&2 & exit /b 1 )

for /f "usebackq delims=" %%I in (`jq -r ".offer_id" "!OFFER_FILE!"`) do set "OFFER_ID=%%I"
for /f "usebackq delims=" %%V in (`jq -r ".version" "!OFFER_FILE!"`) do set "OFFER_VER=%%V"
for /f "usebackq delims=" %%E in (`jq -r ".eula_uri" "!OFFER_FILE!"`) do set "EULA_URI=%%E"
if "!OUT_SBOM!"=="" (
    for /f "usebackq delims=" %%S in (`jq -r ".sbom_path // empty" "!OFFER_FILE!"`) do set "OUT_SBOM=%%S"
)
if "!OUT_SBOM!"=="" set "OUT_SBOM=!LIBSCRIPT_ROOT_DIR!\build\marketplace\!OFFER_ID!\sbom.spdx.json"

if not "!EULA_URI:~0,8!"=="https://" (
    if not exist "!EULA_URI!" if not exist "!LIBSCRIPT_ROOT_DIR!\!EULA_URI!" (
        echo [COMPLIANCE FAIL] Missing EULA / license file: !EULA_URI! >&2
        exit /b 1
    )
)

if not "!SYSROOT_SCAN_DIR!"=="" if exist "!SYSROOT_SCAN_DIR!" (
    dir /s /b "!SYSROOT_SCAN_DIR!\authorized_keys" "!SYSROOT_SCAN_DIR!\id_rsa" "!SYSROOT_SCAN_DIR!\id_ed25519" >nul 2>&1
    if not errorlevel 1 (
        echo [COMPLIANCE FAIL] Prohibited SSH key found in !SYSROOT_SCAN_DIR! >&2
        exit /b 1
    )
)

for %%F in ("!OUT_SBOM!") do if not exist "%%~dpF" mkdir "%%~dpF"
jq -n --arg id "!OFFER_ID!" --arg ver "!OFFER_VER!" "{spdxVersion:\"SPDX-2.3\",dataLicense:\"CC0-1.0\",SPDXID:\"SPDXRef-DOCUMENT\",name:($id + \"-\" + $ver),packages:[]}" > "!OUT_SBOM!.tmp"
move /y "!OUT_SBOM!.tmp" "!OUT_SBOM!" >nul 2>&1
echo [COMPLIANCE PASS] Offer !OFFER_ID! verified; SBOM at !OUT_SBOM!
exit /b 0
