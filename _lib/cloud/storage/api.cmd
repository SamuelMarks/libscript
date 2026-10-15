@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for Object Storage operations on Windows. Wraps native cloud CLIs.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_storage_create aws my-bucket true
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
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

goto :%1

:: ## libscript_storage_create
:: Performs the libscript_storage_create operation and updates component state.
:libscript_storage_create
set "provider=%~2"
set "bucket=%~3"
set "public_web=%~4"
if "%public_web%"=="" set "public_web=false"

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    aws s3api head-bucket --bucket "%bucket%" >nul 2>&1
    if not errorlevel 1 (
        echo Storage bucket '%bucket%' already exists.
    ) else (
        aws s3 mb "s3://%bucket%"
    )
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        aws s3api put-bucket-tagging --bucket "%bucket%" --tagging "TagSet=[{Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%}]"
    )
    if "%public_web%"=="true" (
        aws s3 website "s3://%bucket%/" --index-document index.html
        aws s3api put-public-access-block --bucket "%bucket%" --public-access-block-configuration "BlockPublicAcls=false,IgnorePublicAcls=false,BlockPublicPolicy=false,RestrictPublicBuckets=false"
    )
) else if "%provider%"=="gcp" (
    gcloud storage buckets describe "gs://%bucket%" >nul 2>&1
    if not errorlevel 1 (
        echo Storage bucket '%bucket%' already exists.
    ) else (
        gcloud storage buckets create "gs://%bucket%"
    )
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
    az storage container show --name "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%" >nul 2>&1
    if not errorlevel 1 (
        echo Storage container '%bucket%' already exists.
    ) else (
        set "cmd=az storage container create --name "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%""
        if "%public_web%"=="true" set "cmd=!cmd! --public-access container"
        !cmd!
    )
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        az storage container metadata update --name "%bucket%" --account-name "%LIBSCRIPT_AZURE_ACCOUNT_NAME%" --metadata "%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%"
    )
)
exit /b 0

:: ## libscript_storage_delete
:: Performs the libscript_storage_delete operation and updates component state.
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

:: ## libscript_storage_list
:: Performs the libscript_storage_list operation and updates component state.
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

:: ## libscript_storage_sync
:: Performs the libscript_storage_sync operation and updates component state.
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
