@echo off
:: # distro_import.cmd
::
:: ## Overview
:: Unified multicloud distro image importer on Windows accepting artifacts emitted directly by
:: `package-as {linux,freebsd,illumos,reactos,unikernel}-distro` (or synthesizing on demand)
:: for automated AWS AMI, GCP Compute Image, and Azure Managed Image registration.
::
:: ## Usage
:: distro_import.cmd [--disk=<artifact> | --distro=<target> --profile=<preset>] [--clouds=aws,gcp,azure] [--name=<img_name>] [--aws-bucket=<bkt>] [--gcp-bucket=<bkt>] [--gcp-project=<proj>] [--azure-account=<acct>] [--azure-rg=<rg>] [--azure-gallery=<sig>] [--out=<manifest.json>] [--dry-run] [--allow-stub]

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
set "DISTRO_TARGET="
set "PROFILE_ARG="
set "FORMAT_ARG="
set "CLOUDS_CSV=aws,gcp,azure"
set "IMG_NAME="
set "AWS_BUCKET=libscript-ami-staging"
if not "%IMAGE_IMPORT_AWS_BUCKET%"=="" set "AWS_BUCKET=%IMAGE_IMPORT_AWS_BUCKET%"
set "AWS_REGION=us-east-1"
if not "%IMAGE_IMPORT_AWS_REGION%"=="" set "AWS_REGION=%IMAGE_IMPORT_AWS_REGION%"
set "GCP_BUCKET=libscript-gce-staging"
if not "%IMAGE_IMPORT_GCP_BUCKET%"=="" set "GCP_BUCKET=%IMAGE_IMPORT_GCP_BUCKET%"
set "GCP_PROJECT=libscript-cloud"
if not "%IMAGE_IMPORT_GCP_PROJECT%"=="" set "GCP_PROJECT=%IMAGE_IMPORT_GCP_PROJECT%"
set "AZURE_ACCOUNT=libscriptvhd"
if not "%IMAGE_IMPORT_AZURE_ACCOUNT%"=="" set "AZURE_ACCOUNT=%IMAGE_IMPORT_AZURE_ACCOUNT%"
set "AZURE_RG=libscript-marketplace-rg"
if not "%IMAGE_IMPORT_AZURE_RG%"=="" set "AZURE_RG=%IMAGE_IMPORT_AZURE_RG%"
set "AZURE_GALLERY=%IMAGE_IMPORT_AZURE_GALLERY%"
set "OUT_MANIFEST="
set "DRY_RUN=0"
if "%IMAGE_IMPORT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_args

:: ## show_help
:: Displays CLI usage instructions for distro_import.cmd.
:show_help
echo Usage: distro_import.cmd [--disk=^<artifact^> ^| --distro=^<target^> --profile=^<preset^>] [--clouds=aws,gcp,azure] [--name=^<img_name^>] [--out=^<manifest.json^>] [--dry-run] [--allow-stub]
exit /b 0

:: ## parse_args
:: Parses CLI flags for distro_import.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,7!"=="--disk=" ( set "DISK_PATH=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--disk" ( set "DISK_PATH=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--distro=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--distro" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--target=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--target" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--profile=" ( set "PROFILE_ARG=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--profile" ( set "PROFILE_ARG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--format=" ( set "FORMAT_ARG=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--format" ( set "FORMAT_ARG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--clouds=" ( set "CLOUDS_CSV=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--clouds" ( set "CLOUDS_CSV=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--name=" ( set "IMG_NAME=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--name" ( set "IMG_NAME=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,13!"=="--aws-bucket=" ( set "AWS_BUCKET=!_a:~13!" & shift & goto :parse_args )
if /i "!_a!"=="--aws-bucket" ( set "AWS_BUCKET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,13!"=="--gcp-bucket=" ( set "GCP_BUCKET=!_a:~13!" & shift & goto :parse_args )
if /i "!_a!"=="--gcp-bucket" ( set "GCP_BUCKET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,14!"=="--gcp-project=" ( set "GCP_PROJECT=!_a:~14!" & shift & goto :parse_args )
if /i "!_a!"=="--gcp-project" ( set "GCP_PROJECT=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,16!"=="--azure-account=" ( set "AZURE_ACCOUNT=!_a:~16!" & shift & goto :parse_args )
if /i "!_a!"=="--azure-account" ( set "AZURE_ACCOUNT=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,11!"=="--azure-rg=" ( set "AZURE_RG=!_a:~11!" & shift & goto :parse_args )
if /i "!_a!"=="--azure-rg" ( set "AZURE_RG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,16!"=="--azure-gallery=" ( set "AZURE_GALLERY=!_a:~16!" & shift & goto :parse_args )
if /i "!_a!"=="--azure-gallery" ( set "AZURE_GALLERY=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_MANIFEST=!_a:~6!" & shift & goto :parse_args )
if /i "!_a!"=="--out" ( set "OUT_MANIFEST=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Ensures source artifact exists and dispatches AWS, GCP, and Azure registrations.
:args_done
if "!DISK_PATH!"=="" (
    if "!DISTRO_TARGET!"=="" (
        echo [ERROR] Either --disk or --distro is required. >&2
        exit /b 1
    )
    set "_FMT=!FORMAT_ARG!"
    if "!_FMT!"=="" (
        set "_FMT=raw"
        if /i "!DISTRO_TARGET!"=="unikernel-distro" set "_FMT=uefi-gpt"
    )
    set "_BUILD_ROOT=!LIBSCRIPT_ROOT_DIR!\build"
    if not "!LIBSCRIPT_BUILD_DIR!"=="" set "_BUILD_ROOT=!LIBSCRIPT_BUILD_DIR!"
    if not exist "!_BUILD_ROOT!\image-import" mkdir "!_BUILD_ROOT!\image-import"
    set "DISK_PATH=!_BUILD_ROOT!\image-import\!DISTRO_TARGET!.!_FMT!"
    set "_STUB_ARG="
    if "!ALLOW_STUB!"=="1" set "_STUB_ARG=--allow-stub"
    set "_PROF_CMD="
    if not "!PROFILE_ARG!"=="" set "_PROF_CMD=--profile "!PROFILE_ARG!""
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as "!DISTRO_TARGET!" --format "!_FMT!" --output "!DISK_PATH!" !_PROF_CMD! !_STUB_ARG!
    if errorlevel 1 exit /b 1
)

if not exist "!DISK_PATH!" ( echo [ERROR] Artifact not found: !DISK_PATH! >&2 & exit /b 1 )
if "!OUT_MANIFEST!"=="" set "OUT_MANIFEST=!DISK_PATH!.multicloud-receipt.json"

set "DIGEST=000000000000"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!DISK_PATH!" SHA256 2^>nul') do (
    if "!DIGEST!"=="000000000000" set "DIGEST=%%H"
)
set "SHORT_SHA=!DIGEST:~0,12!"

if exist "!OUT_MANIFEST!" (
    findstr /I /C:"!DIGEST!" "!OUT_MANIFEST!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] Multicloud distro image import already registered for digest !SHORT_SHA!: !OUT_MANIFEST!
        exit /b 0
    )
)

set "_DRY_ARG="
if "!DRY_RUN!"=="1" set "_DRY_ARG=--dry-run"
set "_NAME_ARG="
if not "!IMG_NAME!"=="" set "_NAME_ARG=--name=!IMG_NAME!"
set "_DIST_ARG="
if not "!DISTRO_TARGET!"=="" set "_DIST_ARG=--distro=!DISTRO_TARGET!"

echo ",!CLOUDS_CSV!," | findstr /I ",aws," >nul 2>&1
if not errorlevel 1 (
    set "STACK="
    call "!SCRIPT_DIR!\aws_import.cmd" "--disk=!DISK_PATH!" "--bucket=!AWS_BUCKET!" "--region=!AWS_REGION!" !_NAME_ARG! !_DIST_ARG! !_DRY_ARG!
    if errorlevel 1 exit /b 1
)
echo ",!CLOUDS_CSV!," | findstr /I ",gcp," >nul 2>&1
if not errorlevel 1 (
    set "STACK="
    call "!SCRIPT_DIR!\gcp_import.cmd" "--disk=!DISK_PATH!" "--bucket=!GCP_BUCKET!" "--project=!GCP_PROJECT!" !_NAME_ARG! !_DIST_ARG! !_DRY_ARG!
    if errorlevel 1 exit /b 1
)
echo ",!CLOUDS_CSV!," | findstr /I ",azure," >nul 2>&1
if not errorlevel 1 (
    set "_GAL_ARG="
    if not "!AZURE_GALLERY!"=="" set "_GAL_ARG=--gallery=!AZURE_GALLERY!"
    set "STACK="
    call "!SCRIPT_DIR!\azure_import.cmd" "--disk=!DISK_PATH!" "--account=!AZURE_ACCOUNT!" "--rg=!AZURE_RG!" !_GAL_ARG! !_NAME_ARG! !_DIST_ARG! !_DRY_ARG!
    if errorlevel 1 exit /b 1
)

set "_JSON_DISK=!DISK_PATH:\=/!"
(
echo {"source_artifact":"!_JSON_DISK!","distro_target":"!DISTRO_TARGET!","clouds_requested":"!CLOUDS_CSV!","sha256":"!DIGEST!","dry_run":!DRY_RUN!}
) > "!OUT_MANIFEST!.tmp"
move /y "!OUT_MANIFEST!.tmp" "!OUT_MANIFEST!" >nul 2>&1
echo [OK] Multicloud distro image import manifest written: !OUT_MANIFEST!
exit /b 0
