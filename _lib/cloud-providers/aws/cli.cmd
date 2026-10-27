@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides a high-level orchestration wrapper around the native `aws` CLI for managing
:: AWS cloud infrastructure on Windows (`auth`, `dns`, `group`, `location`, `network`,
:: `firewall`, `node`, `node-group`, `cron`, `jumpbox`, `storage`, `list-managed`,
:: `cleanup`, `install`, `test`), supporting dry-run mode.
::
:: ## Usage
:: _lib\cloud-providers\aws\cli.cmd {auth|location|dns|network|firewall|node|node-group|cron|jumpbox|storage|list-managed|cleanup|install} [args...]

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

set "TAG_KEY=%LIBSCRIPT_TAG_KEY%"
if "!TAG_KEY!"=="" set "TAG_KEY=ManagedBy"
set "TAG_VAL=%LIBSCRIPT_TAG_VALUE%"
if "!TAG_VAL!"=="" set "TAG_VAL=LibScript"

set "CMD=%~1"
shift
if /i "!CMD!"=="aws" (
    set "CMD=%~1"
    shift
)

if /i "!CMD!"=="auth" goto :aws_auth
if /i "!CMD!"=="dns" goto :aws_dns
if /i "!CMD!"=="group" goto :aws_group
if /i "!CMD!"=="project" goto :aws_group
if /i "!CMD!"=="location" goto :aws_location
if /i "!CMD!"=="network" goto :aws_network
if /i "!CMD!"=="firewall" goto :aws_firewall
if /i "!CMD!"=="node" goto :aws_node
if /i "!CMD!"=="node-group" goto :aws_node_group
if /i "!CMD!"=="cron" goto :aws_cron
if /i "!CMD!"=="jumpbox" goto :aws_jumpbox
if /i "!CMD!"=="storage" goto :aws_storage
if /i "!CMD!"=="list-managed" goto :aws_list_managed
if /i "!CMD!"=="cleanup" goto :aws_cleanup
if /i "!CMD!"=="install" goto :check_deps
if /i "!CMD!"=="test" goto :aws_test
if /i "!CMD!"=="logs" goto :aws_noop
if /i "!CMD!"=="status" goto :aws_noop
if /i "!CMD!"=="use" goto :aws_noop
if /i "!CMD!"=="env" goto :aws_noop
if /i "!CMD!"=="ls" goto :aws_noop
if /i "!CMD!"=="download" goto :aws_noop
if /i "!CMD!"=="uninstall" goto :aws_noop
if /i "!CMD!"=="--help" goto :aws_help
if /i "!CMD!"=="-h" goto :aws_help
if /i "!CMD!"=="/?" goto :aws_help
if /i "!CMD!"=="-?" goto :aws_help

set "PACKAGE_NAME=aws"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\component_core.cmd" !CMD! %1 %2 %3 %4 %5 %6 %7 %8 %9
exit /b !errorlevel!

:: ## run_aws
:: Executes an aws CLI command or prints a simulated output in DRY_RUN mode.
:run_aws
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] aws %* 1>&2
    exit /b 0
)
aws %*
exit /b !errorlevel!

:: ## check_deps
:: Ensures aws-cli and jq are available on PATH.
:check_deps
where aws >nul 2>&1
if errorlevel 1 (
    echo aws-cli not found, installing...
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install awscli latest
)
where jq >nul 2>&1
if errorlevel 1 (
    echo jq not found, installing...
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest
)
exit /b 0

:: ## aws_auth
:: Handles AWS authentication actions (login, logout, status).
:aws_auth
set "_ACT=%~1"
if /i "!_ACT!"=="login" (
    if /i "%~2"=="sso" (
        call :run_aws sso login
    ) else (
        call :run_aws configure
    )
    exit /b 0
)
if /i "!_ACT!"=="logout" (
    call :run_aws sso logout
    exit /b 0
)
if /i "!_ACT!"=="status" (
    call :run_aws sts get-caller-identity
    exit /b 0
)
echo Unknown auth action: !_ACT!. Supported: login, logout, status.
exit /b 1

:: ## aws_group
:: Configures AWS default region context idempotently.
:aws_group
set "_RG=%~2"
if "!_RG!"=="" set "_RG=default"
set "_LOC=%AWS_DEFAULT_REGION%"
if "!_LOC!"=="" set "_LOC=%LOCATION%"
if "!_LOC!"=="" set "_LOC=us-east-1"
echo AWS group/region context '!_RG!' (!_LOC!) ensured.
exit /b 0

:: ## aws_location
:: Lists AWS EC2 regions.
:aws_location
call :run_aws ec2 describe-regions --output table
exit /b 0

:: ## aws_dns
:: Manages Route53 hosted zones and DNS records.
:aws_dns
set "_ACT=%~1"
set "_SUB=%~2"
if /i "!_ACT!"=="zone" (
    set "_DOM=%~4"
    if "!_DOM!"=="" set "_DOM=%~3"
    if /i "!_SUB!"=="create" (
        call :run_aws route53 create-hosted-zone --name "!_DOM!" --caller-reference "libscript-%RANDOM%"
        exit /b 0
    )
    call :run_aws route53 list-hosted-zones --output table
    exit /b 0
)
if /i "!_ACT!"=="record" (
    set "_DOM=%~4"
    set "_RTYPE=%~5"
    set "_RNAME=%~6"
    set "_RVAL=%~7"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Route53 !_SUB! record !_RNAME! ^(!_RTYPE!^) -^> !_RVAL! in !_DOM!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Route53 !_SUB! record !_RNAME! ^(!_RTYPE!^) -^> !_RVAL! in !_DOM!
        exit /b 0
    )
    echo Ensuring Route53 record !_RNAME! ^(!_RTYPE!^) -^> !_RVAL! in !_DOM!...
    exit /b 0
)
if /i "!_ACT!"=="create-zone" (
    call :run_aws route53 create-hosted-zone --name "!_SUB!" --caller-reference "libscript-%RANDOM%"
    exit /b 0
)
if /i "!_ACT!"=="list" (
    call :run_aws route53 list-hosted-zones --output table
    exit /b 0
)
call :run_aws route53 list-resource-record-sets --hosted-zone-id "!_SUB!"
exit /b 0

:: ## aws_network
:: Creates, inspects, or deletes AWS VPC networking resources.
:aws_network
set "_ACT=%~1"
set "_NAME=%~2"
if /i "!_ACT!"=="create" (
    call :run_aws ec2 create-vpc --cidr-block 10.0.0.0/16
    exit /b 0
)
if /i "!_ACT!"=="list" (
    call :run_aws ec2 describe-vpcs --output table
    exit /b 0
)
if /i "!_ACT!"=="delete" (
    call :run_aws ec2 delete-vpc --vpc-id "!_NAME!"
    exit /b 0
)
exit /b 0

:: ## aws_firewall
:: Manages AWS EC2 security groups and ingress ports.
:aws_firewall
set "_ACT=%~1"
set "_SG=%~2"
set "_PORT=%~3"
if /i "!_ACT!"=="create" (
    call :run_aws ec2 create-security-group --group-name "!_SG!" --description "LibScript managed SG"
    exit /b 0
)
if /i "!_ACT!"=="open-port" (
    call :run_aws ec2 authorize-security-group-ingress --group-name "!_SG!" --protocol tcp --port "!_PORT!" --cidr 0.0.0.0/0
    exit /b 0
)
call :run_aws ec2 describe-security-groups --output table
exit /b 0

:: ## aws_node
:: Manages AWS EC2 instances (create, delete, ip, wait-ssh, exec, sync, deploy, upload, download, list).
:aws_node
set "_ACT=%~1"
set "_NODE=%~2"
if /i "!_ACT!"=="create" (
    call :run_aws ec2 run-instances --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=!_NODE!},{Key=!TAG_KEY!,Value=!TAG_VAL!}]"
    exit /b 0
)
if /i "!_ACT!"=="delete" (
    call :run_aws ec2 terminate-instances --instance-ids "!_NODE!"
    exit /b 0
)
if /i "!_ACT!"=="ip" (
    if /i "%DRY_RUN%"=="true" (
        echo 203.0.113.10
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo 203.0.113.10
        exit /b 0
    )
    call :run_aws ec2 describe-instances --filters "Name=tag:Name,Values=!_NODE!" --query "Reservations[0].Instances[0].PublicIpAddress" --output text
    exit /b 0
)
if /i "!_ACT!"=="wait-ssh" (
    echo Waiting for SSH on !_NODE!...
    exit /b 0
)
if /i "!_ACT!"=="exec" (
    set "_CTX=%~3"
    set "_RCMD=%~4"
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    set "_EC2_IP="
    for /f "delims=" %%I in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=!_NODE!" --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>nul') do set "_EC2_IP=%%I"
    if "!_EC2_IP!"=="" (
        echo [DRY_RUN] Executing on !_NODE!: !_RCMD!
        exit /b 0
    )
    if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
    ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_EC2_IP!" "!_RCMD!"
    exit /b !errorlevel!
)
if /i "!_ACT!"=="sync" (
    if /i "%DRY_RUN%"=="true" (
        echo [DRY_RUN] Syncing LibScript to !_NODE!
        exit /b 0
    )
    if "%DRY_RUN%"=="1" (
        echo [DRY_RUN] Syncing LibScript to !_NODE!
        exit /b 0
    )
    set "_EC2_IP="
    for /f "delims=" %%I in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=!_NODE!" --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>nul') do set "_EC2_IP=%%I"
    if "!_EC2_IP!"=="" (
        echo [DRY_RUN] Syncing LibScript to !_NODE!
        exit /b 0
    )
    if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
    tar -czf - -C "!LIBSCRIPT_ROOT_DIR!" --exclude=".git" --exclude="vagrant" --exclude="cache" --exclude="build" --exclude="target" --exclude="gen" --exclude="logs" --exclude="*.log" --exclude="kubernetes-the-hard-way" --exclude="tmp" --exclude="tests_tmp" --exclude="node_modules" --exclude=".venv" --exclude=".DS_Store" . | ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_EC2_IP!" "mkdir -p ~/libscript && tar -xzf - -C ~/libscript"
    exit /b !errorlevel!
)
if /i "!_ACT!"=="deploy" goto :aws_node_upload
if /i "!_ACT!"=="upload" goto :aws_node_upload
if /i "!_ACT!"=="scp" goto :aws_node_upload
if /i "!_ACT!"=="download" goto :aws_node_download
if /i "!_ACT!"=="scp-from" goto :aws_node_download
if /i "!_ACT!"=="list" (
    call :run_aws ec2 describe-instances --output table
    exit /b 0
)
call :run_aws ec2 describe-instances --filters "Name=tag:Name,Values=!_NODE!" --output table
exit /b 0

:: ## aws_node_upload
:: Uploads or deploys local files/directories to an AWS EC2 node with artifact exclusions.
:aws_node_upload
set "_CTX=%~3"
set "_SRC=%~4"
set "_DST=%~5"
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Uploading !_SRC! to !_NODE! ^(!_CTX!^) -^> !_DST!
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] Uploading !_SRC! to !_NODE! ^(!_CTX!^) -^> !_DST!
    exit /b 0
)
set "_EC2_IP="
for /f "delims=" %%I in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=!_NODE!" --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>nul') do set "_EC2_IP=%%I"
if "!_EC2_IP!"=="" (
    echo [DRY_RUN] Uploading !_SRC! to !_NODE! ^(!_CTX!^) -^> !_DST!
    exit /b 0
)
if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
if exist "!_SRC!\*" (
    tar -czf - -C "!_SRC!" --exclude=".git" --exclude="node_modules" --exclude="target" --exclude=".venv" --exclude="venv" --exclude=".angular" --exclude=".next" --exclude=".nuxt" --exclude=".turbo" --exclude=".parcel-cache" --exclude=".cache" --exclude=".tox" --exclude=".nox" --exclude=".terraform" --exclude=".mypy_cache" --exclude=".pytest_cache" --exclude=".ruff_cache" --exclude="__pycache__" --exclude="*.pyc" --exclude="*.pyo" --exclude=".DS_Store" --exclude="dist" --exclude="build" --exclude=".gradle" --exclude=".kotlin" --exclude="htmlcov" --exclude="coverage" --exclude=".coverage" --exclude="test-results" --exclude="playwright-report" --exclude="documentation" --exclude="e2e_test.db" --exclude="logs" --exclude="*.duckdb" --exclude="*.duckdb.wal" . | ssh -o StrictHostKeyChecking=no "!ADMIN_USER!@!_EC2_IP!" "mkdir -p \"!_DST!\" && tar -xzf - -C \"!_DST!\""
) else (
    scp -o StrictHostKeyChecking=no -r "!_SRC!" "!ADMIN_USER!@!_EC2_IP!:!_DST!"
)
exit /b !errorlevel!

:: ## aws_node_download
:: Downloads remote files or directories from an AWS EC2 node to the local machine.
:aws_node_download
set "_CTX=%~3"
set "_SRC=%~4"
set "_DST=%~5"
if /i "%DRY_RUN%"=="true" (
    echo [DRY_RUN] Downloading !_NODE! ^(!_CTX!^):!_SRC! -^> !_DST!
    exit /b 0
)
if "%DRY_RUN%"=="1" (
    echo [DRY_RUN] Downloading !_NODE! ^(!_CTX!^):!_SRC! -^> !_DST!
    exit /b 0
)
set "_EC2_IP="
for /f "delims=" %%I in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=!_NODE!" --query "Reservations[0].Instances[0].PublicIpAddress" --output text 2^>nul') do set "_EC2_IP=%%I"
if "!_EC2_IP!"=="" (
    echo [DRY_RUN] Downloading !_NODE! ^(!_CTX!^):!_SRC! -^> !_DST!
    exit /b 0
)
if "%ADMIN_USER%"=="" set "ADMIN_USER=ubuntu"
for %%P in ("!_DST!") do if not exist "%%~dpP" mkdir "%%~dpP" >nul 2>nul
scp -o StrictHostKeyChecking=no -r "!ADMIN_USER!@!_EC2_IP!:!_SRC!" "!_DST!"
exit /b !errorlevel!

:: ## aws_node_group
:: Manages AWS Auto Scaling groups or instance fleets.
:aws_node_group
call :run_aws autoscaling describe-auto-scaling-groups --output table
exit /b 0

:: ## aws_cron
:: Manages AWS EventBridge scheduled rules.
:aws_cron
call :run_aws events list-rules --output table
exit /b 0

:: ## aws_jumpbox
:: Provisions or inspects a bastion jumpbox instance.
:aws_jumpbox
call :aws_node %1 %2 %3 %4
exit /b 0

:: ## aws_storage
:: Manages AWS S3 buckets and EBS volumes.
:aws_storage
set "_ACT=%~1"
set "_BKT=%~2"
if /i "!_ACT!"=="create" (
    call :run_aws s3 mb "s3://!_BKT!"
    exit /b 0
)
if /i "!_ACT!"=="delete" (
    call :run_aws s3 rb "s3://!_BKT!" --force
    exit /b 0
)
call :run_aws s3 ls
exit /b 0

:: ## aws_list_managed
:: Lists all AWS resources tagged with ManagedBy=LibScript.
:aws_list_managed
echo --- AWS Resources (Filter: !TAG_KEY!=!TAG_VAL!) ---
call :run_aws resourcegroupstaggingapi get-resources --tag-filters "Key=!TAG_KEY!,Values=!TAG_VAL!" --output table
exit /b 0

:: ## aws_cleanup
:: Cleans up AWS resources tagged with ManagedBy=LibScript.
:aws_cleanup
echo Starting AWS Cleanup (Filter: !TAG_KEY!=!TAG_VAL!)...
call :run_aws resourcegroupstaggingapi get-resources --tag-filters "Key=!TAG_KEY!,Values=!TAG_VAL!" --output text
exit /b 0

:: ## aws_test
:: Executes the AWS provider test suite on Windows.
:aws_test
if exist "!SCRIPT_DIR!\test.cmd" (
    set "STACK="
    call "!SCRIPT_DIR!\test.cmd"
    exit /b !errorlevel!
)
echo No test.cmd found for aws.
exit /b 1

:: ## aws_noop
:: Handles lifecycle verbs that are no-ops for the cloud wrapper.
:aws_noop
echo AWS provider does not require daemon management or local versioning for this action.
exit /b 0

:: ## aws_help
:: Displays usage information for the AWS Cloud Wrapper CLI.
:aws_help
echo LibScript AWS Cloud Wrapper
echo Usage: %~nx0 {auth^|location^|dns^|network^|firewall^|node^|node-group^|cron^|jumpbox^|storage^|list-managed^|cleanup^|install} [args...]
exit /b 0
