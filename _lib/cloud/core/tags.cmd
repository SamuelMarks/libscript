@echo off
:: # tags.cmd
::
:: ## Overview
:: Provides global configuration for tag-based resource management, and utilities 
:: for formatting tags according to provider requirements (AWS, GCP, Azure) on Windows.
::
:: ## Usage
:: call "%~dp0tags.cmd" :init
:: call "%~dp0tags.cmd" :libscript_format_tags aws

goto :%1

:: ## init
:: Executes init functionality.
:init
if "%LIBSCRIPT_TAG_ENABLE%"=="" set "LIBSCRIPT_TAG_ENABLE=true"
if "%LIBSCRIPT_TAG_KEY%"=="" set "LIBSCRIPT_TAG_KEY=libscript"
if "%LIBSCRIPT_TAG_VALUE%"=="" set "LIBSCRIPT_TAG_VALUE=managed"
exit /b 0

:: ## libscript_verify_managed
:: Verifies if a cloud resource is managed by libscript (i.e. has the correct tag).
:: If the resource is not managed, it exits with an error unless 
:: LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1 is set, in which case it warns.
::
:: Arguments:
::   %2 - Provider (aws, gcp, azure)
::   %3 - Resource Type (node, network, firewall, storage, dns, volume, cdn, cert, gpu-vm, tpu-vm, filestore)
::   %4 - Resource Name or ID
::   %5 - (Optional) Resource Group (for Azure) or Zone/Region (for GCP depending on resource)
::
:: Returns:
::   errorlevel 0 if managed (or overridden), 1 if not managed.
:libscript_verify_managed
setlocal EnableDelayedExpansion
set "provider=%~2"
set "type=%~3"
set "name=%~4"
set "rg=%~5"
set "actual_val="

if not "!LIBSCRIPT_TAG_ENABLE!"=="true" (
    endlocal
    exit /b 0
)

if "%provider%"=="aws" (
    if "%type%"=="node" (
        for /f "tokens=*" %%i in ('aws ec2 describe-instances --filters "Name=tag:Name,Values=!name!" --query "Reservations[0].Instances[0].Tags[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="network" (
        for /f "tokens=*" %%i in ('aws ec2 describe-vpcs --filters "Name=tag:Name,Values=!name!" --query "Vpcs[0].Tags[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="firewall" (
        for /f "tokens=*" %%i in ('aws ec2 describe-security-groups --filters "Name=group-name,Values=!name!" --query "SecurityGroups[0].Tags[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="storage" (
        for /f "tokens=*" %%i in ('aws s3api get-bucket-tagging --bucket "!name!" --query "TagSet[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="dns" (
        for /f "tokens=*" %%i in ('aws route53 list-tags-for-resource --resource-type hostedzone --resource-id "!name!" --query "ResourceTagSet.Tags[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="volume" (
        for /f "tokens=*" %%i in ('aws ec2 describe-volumes --volume-ids "!name!" --query "Volumes[0].Tags[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="cdn" (
        for /f "tokens=*" %%i in ('aws cloudfront list-tags-for-resource --resource "!name!" --query "Tags.Items[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="cert" (
        for /f "tokens=*" %%i in ('aws acm list-tags-for-certificate --certificate-arn "!name!" --query "Tags[?Key=='!LIBSCRIPT_TAG_KEY!'].Value" --output text 2^>nul') do set "actual_val=%%i"
    )
) else if "%provider%"=="gcp" (
    if "%type%"=="node" (
        for /f "tokens=*" %%i in ('gcloud compute instances describe "!name!" --zone="!rg!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="network" (
        for /f "tokens=*" %%i in ('gcloud compute networks describe "!name!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="firewall" (
        for /f "tokens=*" %%i in ('gcloud compute firewall-rules describe "!name!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="storage" (
        for /f "tokens=*" %%i in ('gcloud storage buckets describe "gs://!name!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="dns" (
        for /f "tokens=*" %%i in ('gcloud dns managed-zones describe "!name!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="volume" (
        for /f "tokens=*" %%i in ('gcloud compute disks describe "!name!" --zone="!rg!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="cdn" (
        for /f "tokens=*" %%i in ('gcloud compute backend-buckets describe "!name!-backend" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="cert" (
        for /f "tokens=*" %%i in ('gcloud compute ssl-certificates describe "!name!" --global --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="gpu-vm" (
        for /f "tokens=*" %%i in ('gcloud compute instances describe "!name!" --zone="!rg!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="tpu-vm" (
        for /f "tokens=*" %%i in ('gcloud compute tpus tpu-vm describe "!name!" --zone="!rg!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="filestore" (
        for /f "tokens=*" %%i in ('gcloud filestore instances describe "!name!" --zone="!rg!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="qr" (
        for /f "tokens=*" %%i in ('gcloud alpha compute tpus queued-resources describe "!name!" --zone="!rg!" --format="value(labels.!LIBSCRIPT_TAG_KEY!)" 2^>nul') do set "actual_val=%%i"
    )
) else if "%provider%"=="azure" (
    if "%type%"=="node" (
        for /f "tokens=*" %%i in ('az vm show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="network" (
        for /f "tokens=*" %%i in ('az network vnet show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="firewall" (
        for /f "tokens=*" %%i in ('az network nsg show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="storage" (
        for /f "tokens=*" %%i in ('az storage account show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="dns" (
        for /f "tokens=*" %%i in ('az network dns zone show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="volume" (
        for /f "tokens=*" %%i in ('az disk show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    ) else if "%type%"=="cdn" (
        for /f "tokens=*" %%i in ('az cdn profile show -g "!rg!" -n "!name!" --query "tags.!LIBSCRIPT_TAG_KEY!" -o tsv 2^>nul') do set "actual_val=%%i"
    )
)

if "!actual_val!"=="!LIBSCRIPT_TAG_VALUE!" (
    endlocal
    exit /b 0
)

if "!LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION!"=="1" (
    echo [WARNING] Resource "!name!" is not managed by libscript. Proceeding due to override flag. >&2
    endlocal
    exit /b 0
)
if "!LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION!"=="true" (
    echo [WARNING] Resource "!name!" is not managed by libscript. Proceeding due to override flag. >&2
    endlocal
    exit /b 0
)

echo [ERROR] Refusing to modify "!name!": Resource is not managed by libscript ^(missing tag^). Set LIBSCRIPT_ALLOW_ANY_TAG_MANIPULATION=1 to override. >&2
endlocal
exit /b 1

:: ## libscript_format_tags
:: Executes libscript_format_tags functionality.
:libscript_format_tags
set "provider=%~2"
if not "%LIBSCRIPT_TAG_ENABLE%"=="true" exit /b 0

if "%provider%"=="aws" (
    echo --tags Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="gcp" (
    echo --labels=%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="azure" (
    echo --tags %LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%
) else (
    echo Error: Unknown cloud provider "%provider%" for tagging. >&2
    exit /b 1
)
exit /b 0

:: ## libscript_format_tag_filter
:: Executes libscript_format_tag_filter functionality.
:libscript_format_tag_filter
set "provider=%~2"
if not "%LIBSCRIPT_TAG_ENABLE%"=="true" exit /b 0

if "%provider%"=="aws" (
    echo --filters Name=tag:%LIBSCRIPT_TAG_KEY%,Values=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="gcp" (
    echo --filter=labels.%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%
) else if "%provider%"=="azure" (
    echo --query "[?tags.%LIBSCRIPT_TAG_KEY% == '%LIBSCRIPT_TAG_VALUE%']"
) else (
    echo Error: Unknown cloud provider "%provider%" for tag filtering. >&2
    exit /b 1
)
exit /b 0
