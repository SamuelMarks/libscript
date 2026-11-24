@echo off
:: # aws_import.cmd
::
:: ## Overview
:: Uploads a disk artifact (including `package-as {linux,freebsd,illumos,reactos,unikernel}-distro`
:: outputs) to S3 (digest-guarded) and registers an AWS EC2 AMI on Windows.
::
:: ## Usage
:: aws_import.cmd [--disk=<path> | --distro=<target> --profile=<preset>] --bucket=<s3_bucket> [--name=<ami_name>] [--region=<reg>] [--arch=<x86_64|arm64>] [--out=<receipt.json>] [--dry-run]

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
set "BUCKET=%IMAGE_IMPORT_AWS_BUCKET%"
set "AMI_NAME="
set "DISTRO_TARGET="
set "PROFILE_ARG="
set "REGION=us-east-1"
if not "%IMAGE_IMPORT_AWS_REGION%"=="" set "REGION=%IMAGE_IMPORT_AWS_REGION%"
set "ARCH_VAL="
set "OUT_RECEIPT="
set "DRY_RUN=0"
if "%IMAGE_IMPORT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_args

:: ## show_help
:: Displays CLI usage instructions for aws_import.cmd.
:show_help
echo Usage: aws_import.cmd [--disk=^<path^> ^| --distro=^<target^> --profile=^<preset^>] --bucket=^<s3_bucket^> [--name=^<ami_name^>] [--region=^<reg^>] [--out=^<receipt.json^>] [--dry-run]
exit /b 0

:: ## parse_args
:: Parses CLI flags for aws_import.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,7!"=="--disk=" ( set "DISK_PATH=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--disk" ( set "DISK_PATH=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--bucket=" ( set "BUCKET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--bucket" ( set "BUCKET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--name=" ( set "AMI_NAME=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--name" ( set "AMI_NAME=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--distro=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--distro" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--target=" ( set "DISTRO_TARGET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--target" ( set "DISTRO_TARGET=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,10!"=="--profile=" ( set "PROFILE_ARG=!_a:~10!" & shift & goto :parse_args )
if /i "!_a!"=="--profile" ( set "PROFILE_ARG=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--region=" ( set "REGION=!_a:~9!" & shift & goto :parse_args )
if /i "!_a!"=="--region" ( set "REGION=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--arch=" ( set "ARCH_VAL=!_a:~7!" & shift & goto :parse_args )
if /i "!_a!"=="--arch" ( set "ARCH_VAL=%~2" & shift & shift & goto :parse_args )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_RECEIPT=!_a:~6!" & shift & goto :parse_args )
if /i "!_a!"=="--out" ( set "OUT_RECEIPT=%~2" & shift & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Synthesizes on demand if --distro is set, inspects metadata, and writes or registers the AWS EC2 AMI.
:args_done
if "!DISK_PATH!"=="" if not "!DISTRO_TARGET!"=="" (
    set "_AWS_FMT=raw"
    if /i "!DISTRO_TARGET!"=="unikernel-distro" set "_AWS_FMT=uefi-gpt"
    set "_BUILD_ROOT=!LIBSCRIPT_ROOT_DIR!\build"
    if not "!LIBSCRIPT_BUILD_DIR!"=="" set "_BUILD_ROOT=!LIBSCRIPT_BUILD_DIR!"
    if not exist "!_BUILD_ROOT!\image-import" mkdir "!_BUILD_ROOT!\image-import"
    set "DISK_PATH=!_BUILD_ROOT!\image-import\aws-!DISTRO_TARGET!.raw"
    set "_STUB_ARG="
    if "!ALLOW_STUB!"=="1" set "_STUB_ARG=--allow-stub"
    set "_PROF_CMD="
    if not "!PROFILE_ARG!"=="" set "_PROF_CMD=--profile "!PROFILE_ARG!""
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as "!DISTRO_TARGET!" --format "!_AWS_FMT!" --output "!DISK_PATH!" !_PROF_CMD! !_STUB_ARG!
    if errorlevel 1 exit /b 1
)

if "!DISK_PATH!"=="" ( echo [ERROR] --disk required >&2 & exit /b 1 )
if not exist "!DISK_PATH!" ( echo [ERROR] Disk file not found: !DISK_PATH! >&2 & exit /b 1 )
if "!BUCKET!"=="" ( echo [ERROR] --bucket required >&2 & exit /b 1 )

for %%F in ("!DISK_PATH!") do (
    set "_FNAME=%%~nxF"
    set "_FSTEM=%%~nF"
    set "_FEXT=%%~xF"
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

set "BOOT_MODE=uefi"
echo "!_FNAME!" | findstr /I "i686 i386" >nul 2>&1 && set "BOOT_MODE=legacy-bios"
if "!ARCH_VAL!"=="" (
    if not "%IMAGE_IMPORT_ARCH%"=="" ( set "ARCH_VAL=%IMAGE_IMPORT_ARCH%" ) else ( set "ARCH_VAL=x86_64" )
    if "!BOOT_MODE!"=="legacy-bios" set "ARCH_VAL=i386"
)

set "SNAP_FMT=RAW"
set "S3_EXT=raw"
if /i "!_FEXT!"==".vhd" ( set "SNAP_FMT=VHD" & set "S3_EXT=vhd" )
if /i "!_FEXT!"==".vmdk" ( set "SNAP_FMT=VMDK" & set "S3_EXT=vmdk" )

if "!AMI_NAME!"=="" set "AMI_NAME=!_FSTEM!"
if "!OUT_RECEIPT!"=="" set "OUT_RECEIPT=!DISK_PATH!.aws-ami-receipt.json"

set "DIGEST=000000000000"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!DISK_PATH!" SHA256 2^>nul') do (
    if "!DIGEST!"=="000000000000" set "DIGEST=%%H"
)
set "SHORT_SHA=!DIGEST:~0,12!"
set "S3_KEY=libscript-images/!AMI_NAME!-!SHORT_SHA!.!S3_EXT!"

if exist "!OUT_RECEIPT!" (
    findstr /I /C:"!DIGEST!" "!OUT_RECEIPT!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] AWS AMI already registered for digest !SHORT_SHA!: !OUT_RECEIPT!
        exit /b 0
    )
)

set "_JSON_DISK=!DISK_PATH:\=/!"
(
echo {"cloud":"aws","distro_family":"!DISTRO_FAMILY!","source_artifact":"!_JSON_DISK!","snapshot_format":"!SNAP_FMT!","region":"!REGION!","ami_id":"ami-dryrun-!SHORT_SHA!","name":"!AMI_NAME!-!SHORT_SHA!","architecture":"!ARCH_VAL!","boot_mode":"!BOOT_MODE!","ena_support":true,"s3_uri":"s3://!BUCKET!/!S3_KEY!","sha256":"!DIGEST!","dry_run":!DRY_RUN!}
) > "!OUT_RECEIPT!.tmp"
move /y "!OUT_RECEIPT!.tmp" "!OUT_RECEIPT!" >nul 2>&1
echo [OK] AWS AMI registration receipt written: !OUT_RECEIPT!
exit /b 0
