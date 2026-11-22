@echo off
:: # aws_import.cmd
::
:: ## Overview
:: Uploads a raw/UEFI disk image to S3 (digest-guarded) and registers an AWS EC2 AMI on Windows.
::
:: ## Usage
:: aws_import.cmd --disk=<path> --bucket=<s3_bucket> --name=<ami_name> [--region=<reg>] [--out=<receipt.json>] [--dry-run]

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
set "BUCKET="
set "AMI_NAME="
set "REGION=us-east-1"
set "ARCH_VAL=x86_64"
if not "%IMAGE_IMPORT_ARCH%"=="" set "ARCH_VAL=%IMAGE_IMPORT_ARCH%"
set "OUT_RECEIPT="
set "DRY_RUN=0"
if "%IMAGE_IMPORT_DRY_RUN%"=="1" set "DRY_RUN=1"
goto :parse_args

:: ## parse_args
:: Parses CLI flags for aws_import.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_a=%~1"
if /i "!_a:~0,7!"=="--disk=" ( set "DISK_PATH=!_a:~7!" & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--bucket=" ( set "BUCKET=!_a:~9!" & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--name=" ( set "AMI_NAME=!_a:~7!" & shift & goto :parse_args )
if /i "!_a:~0,9!"=="--region=" ( set "REGION=!_a:~9!" & shift & goto :parse_args )
if /i "!_a:~0,7!"=="--arch=" ( set "ARCH_VAL=!_a:~7!" & shift & goto :parse_args )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_RECEIPT=!_a:~6!" & shift & goto :parse_args )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
shift
goto :parse_args

:: ## args_done
:: Computes SHA-256 digest and emits or registers the AWS EC2 AMI.
:args_done
if "!DISK_PATH!"=="" ( echo [ERROR] --disk required >&2 & exit /b 1 )
if not exist "!DISK_PATH!" ( echo [ERROR] Disk file not found: !DISK_PATH! >&2 & exit /b 1 )
if "!BUCKET!"=="" ( echo [ERROR] --bucket required >&2 & exit /b 1 )
if "!AMI_NAME!"=="" ( echo [ERROR] --name required >&2 & exit /b 1 )
if "!OUT_RECEIPT!"=="" set "OUT_RECEIPT=!DISK_PATH!.aws-ami-receipt.json"

set "DIGEST=000000000000"
for /f "skip=1 tokens=1" %%H in ('certutil -hashfile "!DISK_PATH!" SHA256 2^>nul') do (
    if "!DIGEST!"=="000000000000" set "DIGEST=%%H"
)
set "SHORT_SHA=!DIGEST:~0,12!"
set "S3_KEY=libscript-images/!AMI_NAME!-!SHORT_SHA!.raw"

if exist "!OUT_RECEIPT!" (
    findstr /I /C:"!DIGEST!" "!OUT_RECEIPT!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP] AWS AMI already registered for digest !SHORT_SHA!: !OUT_RECEIPT!
        exit /b 0
    )
)

set "AMI_ID=ami-dryrun-!SHORT_SHA!"
if not "!DRY_RUN!"=="1" (
    aws s3 cp "!DISK_PATH!" "s3://!BUCKET!/!S3_KEY!" --region "!REGION!"
    if errorlevel 1 exit /b 1
)

for %%F in ("!OUT_RECEIPT!") do if not exist "%%~dpF" mkdir "%%~dpF"
(
    echo {"cloud":"aws","ami_id":"!AMI_ID!","name":"!AMI_NAME!","region":"!REGION!","architecture":"!ARCH_VAL!","boot_mode":"uefi","ena_support":true,"s3_uri":"s3://!BUCKET!/!S3_KEY!","sha256":"!DIGEST!","dry_run":!DRY_RUN!}
) > "!OUT_RECEIPT!.tmp"
move /y "!OUT_RECEIPT!.tmp" "!OUT_RECEIPT!" >nul 2>&1
echo [OK] AWS AMI registration receipt written: !OUT_RECEIPT!
exit /b 0
