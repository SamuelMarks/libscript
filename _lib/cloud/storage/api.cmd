@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for Object Storage operations on Windows. Wraps native cloud CLIs.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_storage_create aws my-bucket true

goto :%1

:libscript_storage_create
set "provider=%~2"
set "bucket=%~3"
set "public_web=%~4"
if "%public_web%"=="" set "public_web=false"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    aws s3 mb "s3://%bucket%"
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        aws s3api put-bucket-tagging --bucket "%bucket%" --tagging "TagSet=[{Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%}]"
    )
    if "%public_web%"=="true" (
        aws s3 website "s3://%bucket%/" --index-document index.html
        aws s3api put-public-access-block --bucket "%bucket%" --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
    )
) else if "%provider%"=="gcp" (
    gcloud storage buckets create "gs://%bucket%"
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        gcloud storage buckets update "gs://%bucket%" --update-labels="%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%"
    )
    if "%public_web%"=="true" (
        gcloud storage buckets update "gs://%bucket%" --web-main-page-suffix=index.html
        gcloud storage buckets add-iam-policy-binding "gs://%bucket%" --member="allUsers" --role="roles/storage.objectViewer"
    )
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_ACCOUNT_NAME%"=="" (
        echo Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations. >&2
        exit /b 1
    )
    set "cmd=az storage container create --name "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%""
    if "%public_web%"=="true" set "cmd=!cmd! --public-access container"
    %cmd%
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        az storage container metadata update --name "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%" --metadata "%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%"
    )
)
exit /b 0

:libscript_storage_delete
set "provider=%~2"
set "bucket=%~3"

if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
    call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed "%provider%" storage "%bucket%" "%LIBSCRIPT_AZURE_ACCOUNT_NAME%"
    if errorlevel 1 exit /b 1
)

if "%provider%"=="aws" (
    aws s3 rb "s3://%bucket%" --force
) else if "%provider%"=="gcp" (
    gcloud storage buckets delete "gs://%bucket%"
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_ACCOUNT_NAME%"=="" (
        echo Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations. >&2
        exit /b 1
    )
    az storage container delete --name "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%"
)
exit /b 0

:libscript_storage_list
set "provider=%~2"
call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        aws resourcegroupstaggingapi get-resources --resource-type-filters s3 --tag-filters "Key=%LIBSCRIPT_TAG_KEY%,Values=%LIBSCRIPT_TAG_VALUE%" --query "ResourceTagMappingList[].ResourceARN" --output text
    ) else (
        aws s3 ls
    )
) else if "%provider%"=="gcp" (
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        gcloud storage buckets list --filter="labels.%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%"
    ) else (
        gcloud storage buckets list
    )
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_ACCOUNT_NAME%"=="" (
        echo Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations. >&2
        exit /b 1
    )
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        az storage container list --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%" --query "[?metadata.%LIBSCRIPT_TAG_KEY% == '%LIBSCRIPT_TAG_VALUE%'].name" --output tsv
    ) else (
        az storage container list --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%" --query "[].name" --output tsv
    )
)
exit /b 0

:libscript_storage_sync
set "provider=%~2"
set "bucket=%~3"
set "local_dir=%~4"

if not exist "%local_dir%\" (
    echo Error: Local directory '%local_dir%' does not exist. >&2
    exit /b 1
)

if "%provider%"=="aws" (
    aws s3 sync "%local_dir%" "s3://%bucket%/"
) else if "%provider%"=="gcp" (
    gcloud storage rsync -r "%local_dir%" "gs://%bucket%/"
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_ACCOUNT_NAME%"=="" (
        echo Error: LIBSCRIPT_AZURE_ACCOUNT_NAME must be set for Azure storage operations. >&2
        exit /b 1
    )
    az storage blob sync -c "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%" -s "%local_dir%"
)
exit /b 0
