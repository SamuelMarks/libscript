@echo off
:: # gcp_import.cmd
::
:: ## Overview
:: Packages a disk artifact (or existing `disk.raw.tar.gz` archive) from
:: `package-as {linux,freebsd,illumos,reactos,unikernel}-distro`, uploads to GCS,
:: and registers a Shielded GCE Compute Image on Windows.
::
:: ## Usage
:: gcp_import.cmd [--disk=<artifact_or_tar_gz> | --distro=<target> --profile=<preset>] --bucket=<gcs_bucket> --project=<gcp_proj> [--name=<img_name>] [--arch=<X86_64|ARM64>] [--out=<receipt.json>] [--dry-run]

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
set "BUCKET=%IMAGE_IMPORT_GCP_BUCKET%"
set "PROJECT_ID=%IMAGE_IMPORT_GCP_PROJECT%"
set "IMG_NAME="
set "DISTRO_TARGET="
set "PROFILE_ARG="
set "ARCH_VAL=X86_64"
if /i "%IMAGE_IMPORT_ARCH%"=="arm64" set "ARCH_VAL=ARM64"
set "OUT_RECEIPT="
set "DRY_RUN=0"
if "%IMAGE_IMPORT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_args

:: ## show_help
:: Displays CLI usage instructions for gcp_import.cmd.
:show_help
echo Usage: gcp_import.cmd [--disk=^<path^> ^| --distro=^<target^> --profile=^<preset^>] --bucket=^<gcs_bucket^> --project=^<gcp_proj^> [--name=^<img_name^>] [--out=^<receipt.json^>] [--dry-run]
exit /b 0

:: ## parse_args
:: Parses CLI flags for gcp_import.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,7!"=="--disk=" ( set "DISK_PATH=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--disk" ( set "DISK_PATH=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--bucket=" ( set "BUCKET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--bucket" ( set "BUCKET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--project=" ( set "PROJECT_ID=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--project" ( set "PROJECT_ID=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--name=" ( set "IMG_NAME=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--name" ( set "IMG_NAME=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--distro=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--distro" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--target=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--target" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--profile=" ( set "PROFILE_ARG=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--profile" ( set "PROFILE_ARG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--arch=" ( set "ARCH_VAL=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--arch" ( set "ARCH_VAL=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_RECEIPT=!_a:~6!" & shift & goto :parse_args )
if /i "!_a!"=="--out" ( set "OUT_RECEIPT=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Packages raw distro artifacts into disk.raw.tar.gz and writes or registers the GCP Compute Engine image.
:args_done
if "!DISK_PATH!"=="" if not "!DISTRO_TARGET!"=="" (
    set "_GCP_FMT=raw"
    if /i "!DISTRO_TARGET!"=="unikernel-distro" set "_GCP_FMT=uefi-gpt"
    set "_BUILD_ROOT=!LIBSCRIPT_ROOT_DIR!\build"
    if not "!LIBSCRIPT_BUILD_DIR!"=="" set "_BUILD_ROOT=!LIBSCRIPT_BUILD_DIR!"
    if not exist "!_BUILD_ROOT!\image-import" mkdir "!_BUILD_ROOT!\image-import"
    set "DISK_PATH=!_BUILD_ROOT!\image-import\gcp-!DISTRO_TARGET!.raw"
    set "_STUB_ARG="
    if "!ALLOW_STUB!"=="1" set "_STUB_ARG=--allow-stub"
    set "_PROF_CMD="
    if not "!PROFILE_ARG!"=="" set "_PROF_CMD=--profile "!PROFILE_ARG!""
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as "!DISTRO_TARGET!" --format "!_GCP_FMT!" --output "!DISK_PATH!" !_PROF_CMD! !_STUB_ARG!
    if errorlevel 1 exit /b 1
)

if "!DISK_PATH!"=="" ( echo [ERROR] --disk required >&2 & exit /b 1 )
if not exist "!DISK_PATH!" ( echo [ERROR] Disk artifact not found: !DISK_PATH! >&2 & exit /b 1 )
if "!BUCKET!"=="" ( echo [ERROR] --bucket required >&2 & exit /b 1 )
if "!PROJECT_ID!"=="" ( echo [ERROR] --project required >&2 & exit /b 1 )

for %%F in ("!DISK_PATH!") do (
    set "_FNAME=%%~nxF"
    set "_FSTEM=%%~nF"
)

set "DISTRO_FAMILY=generic"
echo "!_FNAME!" | findstr /I "linux" >nul 2>&1 && set "DISTRO_FAMILY=linux"
echo "!_FNAME!" | findstr /I "freebsd" >nul 2>&1 && set "DISTRO_FAMILY=freebsd"
echo "!_FNAME!" | findstr /I "illumos" >nul 2>&1 && set "DISTRO_FAMILY=illumos"
echo "!_FNAME!" | findstr /I "reactos" >nul 2>&1 && set "DISTRO_FAMILY=reactos"
echo "!_FNAME!" | findstr /I "unikernel uefi-gpt" >nul 2>&1 && set "DISTRO_FAMILY=unikernel"
if not "!DISTRO_TARGET!"=="" set "DISTRO_FAMILY=!DISTRO_TARGET:-distro=!"

for %%S in ("!DISK_PATH!.distro.stamp" "!DISK_PATH!.stamp") do (
    if exist "%%~S" (
        findstr /I "freebsd" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=freebsd"
        findstr /I "illumos" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=illumos"
        findstr /I "reactos" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=reactos"
        findstr /I "unikernel framework=" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=unikernel"
        findstr /I "linux lfs" "%%~S" >nul 2>&1 && set "DISTRO_FAMILY=linux"
    )
)

if /i "!ARCH_VAL!"=="arm64" set "ARCH_VAL=ARM64"
if /i "!ARCH_VAL!"=="aarch64" set "ARCH_VAL=ARM64"
if /i not "!ARCH_VAL!"=="ARM64" set "ARCH_VAL=X86_64"

if "!IMG_NAME!"=="" set "IMG_NAME=!_FSTEM!"
if "!OUT_RECEIPT!"=="" set "OUT_RECEIPT=!DISK_PATH!.gcp-image-receipt.json"

set "DIGEST=000000000000"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!DISK_PATH!" SHA256 2^>nul') do (
    if "!DIGEST!"=="000000000000" set "DIGEST=%%H"
)
set "SHORT_SHA=!DIGEST:~0,12!"
set "CLEAN_NAME=!IMG_NAME!-!SHORT_SHA!"
set "CLEAN_NAME=!CLEAN_NAME:_=-!"
set "CLEAN_NAME=!CLEAN_NAME:.=-!"
set "GCS_URI=gs://!BUCKET!/libscript-images/!CLEAN_NAME!.disk.raw.tar.gz"
set "SELF_LINK=projects/!PROJECT_ID!/global/images/!CLEAN_NAME!"

if exist "!OUT_RECEIPT!" (
    findstr /I /C:"!DIGEST!" "!OUT_RECEIPT!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] GCP Compute Engine image already registered for digest !SHORT_SHA!: !OUT_RECEIPT!
        exit /b 0
    )
)

set "PACKAGED_ARCHIVE=!DISK_PATH!"
echo "!_FNAME!" | findstr /I "\.tar\.gz$ \.tgz$" >nul 2>&1
if errorlevel 1 (
    set "PACKAGED_ARCHIVE=!DISK_PATH!.gcp-disk.raw.tar.gz"
    if not exist "!PACKAGED_ARCHIVE!" (
        set "_STAGE_DIR=!DISK_PATH!.gcp_stage_!RANDOM!"
        if not exist "!_STAGE_DIR!" mkdir "!_STAGE_DIR!"
        copy /y "!DISK_PATH!" "!_STAGE_DIR!\disk.raw" >nul 2>&1
        where tar >nul 2>&1
        if not errorlevel 1 (
            tar -czf "!PACKAGED_ARCHIVE!" -C "!_STAGE_DIR!" disk.raw
        ) else (
            copy /y "!_STAGE_DIR!\disk.raw" "!PACKAGED_ARCHIVE!" >nul 2>&1
        )
        rmdir /s /q "!_STAGE_DIR!" 2>nul
    )
)

set "_JSON_DISK=!DISK_PATH:\=/!"
set "_JSON_ARCH_PKG=!PACKAGED_ARCHIVE:\=/!"
(
echo {"cloud":"gcp","distro_family":"!DISTRO_FAMILY!","source_artifact":"!_JSON_DISK!","packaged_archive":"!_JSON_ARCH_PKG!","project_id":"!PROJECT_ID!","image_name":"!CLEAN_NAME!","self_link":"!SELF_LINK!","architecture":"!ARCH_VAL!","guest_os_features":["UEFI_COMPATIBLE","GVNIC","VIRTIO_SCSI_MULTIQUEUE"],"gcs_uri":"!GCS_URI!","sha256":"!DIGEST!","dry_run":!DRY_RUN!}
) > "!OUT_RECEIPT!.tmp"
move /y "!OUT_RECEIPT!.tmp" "!OUT_RECEIPT!" >nul 2>&1
echo [OK] GCP Compute Engine image receipt written: !OUT_RECEIPT!
exit /b 0
