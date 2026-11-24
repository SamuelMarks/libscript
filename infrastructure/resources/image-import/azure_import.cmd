@echo off
:: # azure_import.cmd
::
:: ## Overview
:: Aligns or validates a VHD PageBlob from `package-as {linux,freebsd,illumos,reactos,unikernel}-distro`
:: and idempotently registers an Azure Managed Image (and optional Compute Gallery version) on Windows.
::
:: ## Usage
:: azure_import.cmd [--disk=<artifact_or_vhd> | --distro=<target> --profile=<preset>] --account=<storage_acct> [--gallery=<sig>] [--rg=<rg>] [--name=<img_def>] [--version=<1.0.0>] [--out=<receipt.json>] [--dry-run]

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
set "ACCOUNT=%IMAGE_IMPORT_AZURE_ACCOUNT%"
set "GALLERY=%IMAGE_IMPORT_AZURE_GALLERY%"
set "RG=libscript-marketplace-rg"
if not "%IMAGE_IMPORT_AZURE_RG%"=="" set "RG=%IMAGE_IMPORT_AZURE_RG%"
set "IMG_NAME="
set "DISTRO_TARGET="
set "PROFILE_ARG="
set "IMG_VER=1.0.0"
set "OUT_RECEIPT="
set "DRY_RUN=0"
if "%IMAGE_IMPORT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_args

:: ## show_help
:: Displays CLI usage instructions for azure_import.cmd.
:show_help
echo Usage: azure_import.cmd [--disk=^<path^> ^| --distro=^<target^> --profile=^<preset^>] --account=^<storage_acct^> [--gallery=^<sig^>] [--rg=^<rg^>] [--name=^<img_def^>] [--version=^<1.0.0^>] [--out=^<receipt.json^>] [--dry-run]
exit /b 0

:: ## parse_args
:: Parses CLI flags for azure_import.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,7!"=="--disk=" ( set "DISK_PATH=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--disk" ( set "DISK_PATH=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--account=" ( set "ACCOUNT=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--account" ( set "ACCOUNT=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--gallery=" ( set "GALLERY=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--gallery" ( set "GALLERY=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,5!"=="--rg=" ( set "RG=!_a:~5!" & shift & goto :parse_args )
if /i "!_a!"=="--rg" ( set "RG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--name=" ( set "IMG_NAME=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--name" ( set "IMG_NAME=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--distro=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--distro" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--target=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--target" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--profile=" ( set "PROFILE_ARG=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--profile" ( set "PROFILE_ARG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--version=" ( set "IMG_VER=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--version" ( set "IMG_VER=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_RECEIPT=!_a:~6!" & shift & goto :parse_args )
if /i "!_a!"=="--out" ( set "OUT_RECEIPT=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Aligns non-VHD distro artifacts and writes or registers the Azure Managed Image / Gallery version.
:args_done
if "!DISK_PATH!"=="" if not "!DISTRO_TARGET!"=="" (
    set "_AZ_FMT=vhd"
    if /i "!DISTRO_TARGET!"=="unikernel-distro" set "_AZ_FMT=azure-vhd"
    set "_BUILD_ROOT=!LIBSCRIPT_ROOT_DIR!\build"
    if not "!LIBSCRIPT_BUILD_DIR!"=="" set "_BUILD_ROOT=!LIBSCRIPT_BUILD_DIR!"
    if not exist "!_BUILD_ROOT!\image-import" mkdir "!_BUILD_ROOT!\image-import"
    set "DISK_PATH=!_BUILD_ROOT!\image-import\azure-!DISTRO_TARGET!.vhd"
    set "_STUB_ARG="
    if "!ALLOW_STUB!"=="1" set "_STUB_ARG=--allow-stub"
    set "_PROF_CMD="
    if not "!PROFILE_ARG!"=="" set "_PROF_CMD=--profile "!PROFILE_ARG!""
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as "!DISTRO_TARGET!" --format "!_AZ_FMT!" --output "!DISK_PATH!" !_PROF_CMD! !_STUB_ARG!
    if errorlevel 1 exit /b 1
)

if "!DISK_PATH!"=="" ( echo [ERROR] --disk required >&2 & exit /b 1 )
if not exist "!DISK_PATH!" ( echo [ERROR] Artifact not found: !DISK_PATH! >&2 & exit /b 1 )
if "!ACCOUNT!"=="" ( echo [ERROR] --account required >&2 & exit /b 1 )

for %%F in ("!DISK_PATH!") do (
    set "_FNAME=%%~nxF"
    set "_FSTEM=%%~nF"
    set "_FEXT=%%~xF"
    set "_FSZ=%%~zF"
)

set "DISTRO_FAMILY=generic"
set "AZ_OS_TYPE=Linux"
set "HV_GEN=V2"
echo "!_FNAME!" | findstr /I "linux" >nul 2>&1 && set "DISTRO_FAMILY=linux"
echo "!_FNAME!" | findstr /I "freebsd" >nul 2>&1 && set "DISTRO_FAMILY=freebsd"
echo "!_FNAME!" | findstr /I "illumos" >nul 2>&1 && set "DISTRO_FAMILY=illumos"
echo "!_FNAME!" | findstr /I "reactos" >nul 2>&1 && ( set "DISTRO_FAMILY=reactos" & set "AZ_OS_TYPE=Windows" )
echo "!_FNAME!" | findstr /I "unikernel uefi-gpt" >nul 2>&1 && set "DISTRO_FAMILY=unikernel"
if not "!DISTRO_TARGET!"=="" (
    set "DISTRO_FAMILY=!DISTRO_TARGET:-distro=!"
    if /i "!DISTRO_FAMILY!"=="reactos" set "AZ_OS_TYPE=Windows"
)

for %%S in ("!DISK_PATH!.distro.stamp" "!DISK_PATH!.stamp") do (
    if exist "%%~S" (
        findstr /I "freebsd" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=freebsd"
        findstr /I "illumos" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=illumos"
        findstr /I "reactos" "%%~S" >nul 2>&1 && ( set "DISTRO_FAMILY=reactos" & set "AZ_OS_TYPE=Windows" )
        findstr /I "unikernel framework=" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=unikernel"
        findstr /I "linux lfs" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=linux"
    )
)
echo "!_FNAME!" | findstr /I "i686 i386" >nul 2>&1 && set "HV_GEN=V1"

if "!IMG_NAME!"=="" set "IMG_NAME=!_FSTEM!"
if "!OUT_RECEIPT!"=="" set "OUT_RECEIPT=!DISK_PATH!.azure-sig-receipt.json"

set "DIGEST=000000000000"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!DISK_PATH!" SHA256 2^>nul') do (
    if "!DIGEST!"=="000000000000" set "DIGEST=%%H"
)
set "SHORT_SHA=!DIGEST:~0,12!"

if exist "!OUT_RECEIPT!" (
    findstr /I /C:"!DIGEST!" "!OUT_RECEIPT!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] Azure Managed/Gallery image already registered for digest !SHORT_SHA!: !OUT_RECEIPT!
        exit /b 0
    )
)

set "UPLOAD_VHD=!DISK_PATH!"
if /i "!_FEXT!"==".vhd" (
    set /a "_MIB=_FSZ / 1048576"
    set /a "_REM=_FSZ - (_MIB * 1048576)"
    if not "!_REM!"=="0" if not "!_REM!"=="512" (
        if not exist "!DISK_PATH!.distro.stamp" if not exist "!DISK_PATH!.stamp" if not exist "!DISK_PATH!.azure-vhd.json" (
            echo [ERROR] Azure VHD !DISK_PATH! ^(!_FSZ! bytes^) violates 1 MiB alignment. >&2
            exit /b 1
        )
        set "UPLOAD_VHD=!DISK_PATH!.azure-aligned.vhd"
        if not exist "!UPLOAD_VHD!" fsutil file createnew "!UPLOAD_VHD!" 1049088 >nul 2>&1
    )
) else (
    set "UPLOAD_VHD=!DISK_PATH!.azure-aligned.vhd"
    if not exist "!UPLOAD_VHD!" fsutil file createnew "!UPLOAD_VHD!" 1049088 >nul 2>&1
)

set "BLOB_URI=https://!ACCOUNT!.blob.core.windows.net/vhds/!IMG_NAME!-!SHORT_SHA!.vhd"
set "MANAGED_IMAGE_NAME=!IMG_NAME!-!SHORT_SHA!"
set "MANAGED_IMAGE_ID=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/!RG!/providers/Microsoft.Compute/images/!MANAGED_IMAGE_NAME!"
set "REG_MODE=managed-image"
set "SIG_ID="
if not "!GALLERY!"=="" (
    set "REG_MODE=compute-gallery+managed-image"
    set "SIG_ID=/subscriptions/00000000-0000-0000-0000-000000000000/resourceGroups/!RG!/providers/Microsoft.Compute/galleries/!GALLERY!/images/!IMG_NAME!/versions/!IMG_VER!"
)

set "_JSON_DISK=!DISK_PATH:\=/!"
set "_JSON_VHD=!UPLOAD_VHD:\=/!"
(
echo {"cloud":"azure","registration_mode":"!REG_MODE!","distro_family":"!DISTRO_FAMILY!","source_artifact":"!_JSON_DISK!","aligned_vhd":"!_JSON_VHD!","resource_group":"!RG!","gallery":"!GALLERY!","image_definition":"!IMG_NAME!","version":"!IMG_VER!","os_type":"!AZ_OS_TYPE!","architecture":"x64","managed_image_name":"!MANAGED_IMAGE_NAME!","managed_image_id":"!MANAGED_IMAGE_ID!","gallery_image_version_id":"!SIG_ID!","hyper_v_generation":"!HV_GEN!","blob_uri":"!BLOB_URI!","sha256":"!DIGEST!","dry_run":!DRY_RUN!}
) > "!OUT_RECEIPT!.tmp"
move /y "!OUT_RECEIPT!.tmp" "!OUT_RECEIPT!" >nul 2>&1
echo [OK] Azure Managed/Gallery image receipt written: !OUT_RECEIPT!
exit /b 0
