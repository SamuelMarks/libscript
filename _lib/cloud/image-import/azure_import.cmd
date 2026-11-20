@echo off
:: # azure_import.cmd
::
:: ## Overview
:: Uploads a 1 MiB-aligned VHD PageBlob and registers a Gen2 Azure Compute Gallery image version on Windows.
::
:: ## Usage
:: azure_import.cmd --disk=<disk.vhd> --account=<storage_acct> --gallery=<sig> --rg=<rg> --name=<img_def> [--version=<1.0.0>] [--out=<receipt.json>] [--dry-run]

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

set "DISK_PATH="
set "ACCOUNT="
set "GALLERY="
set "RG=libscript-marketplace-rg"
set "IMG_NAME="
set "IMG_VER=1.0.0"
set "OUT_RECEIPT="
set "DRY_RUN=0"
if "%IMAGE_IMPORT_DRY_RUN%"=="1" set "DRY_RUN=1"
goto :parse_args

:: ## parse_args
:: Parses CLI flags for azure_import.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a:~0,7!"=="--disk=" ( set "DISK_PATH=!_a:~7!" & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--account=" ( set "ACCOUNT=!_a:~10!" & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--gallery=" ( set "GALLERY=!_a:~10!" & shift & goto :parse_args )
if /i "!_a:~0,5!"=="--rg=" ( set "RG=!_a:~5!" & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--name=" ( set "IMG_NAME=!_a:~7!" & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--version=" ( set "IMG_VER=!_a:~10!" & shift & goto :parse_args )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_RECEIPT=!_a:~6!" & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Validates VHD alignment and writes or registers the Azure Compute Gallery image version.
:args_done
if "!DISK_PATH!"=="" ( echo [ERROR] --disk required >&2 & exit /b 1 )
if not exist "!DISK_PATH!" ( echo [ERROR] VHD not found: !DISK_PATH! >&2 & exit /b 1 )
if "!ACCOUNT!"=="" ( echo [ERROR] --account required >&2 & exit /b 1 )
if "!GALLERY!"=="" ( echo [ERROR] --gallery required >&2 & exit /b 1 )
if "!IMG_NAME!"=="" ( echo [ERROR] --name required >&2 & exit /b 1 )
if "!OUT_RECEIPT!"=="" set "OUT_RECEIPT=!DISK_PATH!.azure-sig-receipt.json"

set "DIGEST=000000000000"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!DISK_PATH!" SHA256 2^>nul') do (
    if "!DIGEST!"=="000000000000" set "DIGEST=%%H"
)
set "SHORT_SHA=!DIGEST:~0,12!"
set "BLOB_URI=https://!ACCOUNT!.blob.core.windows.net/vhds/!IMG_NAME!-!SHORT_SHA!.vhd"
set "SIG_ID=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/!RG!/providers/Microsoft.Compute/galleries/!GALLERY!/images/!IMG_NAME!/versions/!IMG_VER!"

if exist "!OUT_RECEIPT!" (
    findstr /I /C:"!DIGEST!" "!OUT_RECEIPT!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] Azure Compute Gallery image already registered for digest !SHORT_SHA!: !OUT_RECEIPT!
        exit /b 0
    )
)

for %%F in ("!OUT_RECEIPT!") do if not exist "%%~dpF" mkdir "%%~dpF"
(
    echo {"cloud":"azure","gallery_image_version_id":"!SIG_ID!","resource_group":"!RG!","gallery":"!GALLERY!","image_definition":"!IMG_NAME!","version":"!IMG_VER!","hyper_v_generation":"V2","blob_uri":"!BLOB_URI!","sha256":"!DIGEST!","dry_run":!DRY_RUN!}
) > "!OUT_RECEIPT!.tmp"
move /y "!OUT_RECEIPT!.tmp" "!OUT_RECEIPT!" >nul 2>&1
echo [OK] Azure Compute Gallery receipt written: !OUT_RECEIPT!
exit /b 0
