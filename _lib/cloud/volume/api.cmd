@echo off
:: # api.cmd
::
:: ## Overview
:: API implementation for Block Storage (Volumes) operations on Windows. Wraps native cloud CLIs.
::
:: ## Usage
:: call "%~dp0api.cmd" :libscript_volume_create aws 10 us-east-1a gp3

goto :%1

:: ## libscript_volume_create
:: Executes libscript_volume_create functionality.
:libscript_volume_create
set "provider=%~2"
set "size=%~3"
set "zone=%~4"
set "vtype=%~5"
set "vname=%~6"

if "%size%"=="" set "size=10"
if "%vname%"=="" set "vname=vol-libscript"

if "%zone%"=="" (
    echo Error: --zone (or LIBSCRIPT_VOLUME_ZONE) is required for volume creation. >&2
    exit /b 1
)

call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    if "%vtype%"=="" set "vtype=gp3"

    for /f "tokens=*" %%i in ('aws ec2 describe-volumes --filters "Name=tag:Name,Values=%vname%" "Name=availability-zone,Values=%zone%" --query "Volumes[0].VolumeId" --output text 2^>nul') do set "existing_vol=%%i"
    if not "!existing_vol!"=="" if not "!existing_vol!"=="None" (
        echo Volume '%vname%' already exists: !existing_vol!
        exit /b 0
    )

    set "cmd=aws ec2 create-volume --availability-zone "%zone%" --size "%size%" --volume-type "%vtype%""
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        set "cmd=!cmd! --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=%vname%},{Key=%LIBSCRIPT_TAG_KEY%,Value=%LIBSCRIPT_TAG_VALUE%}]""
    ) else (
        set "cmd=!cmd! --tag-specifications "ResourceType=volume,Tags=[{Key=Name,Value=%vname%}]""
    )
    %cmd%
) else if "%provider%"=="gcp" (
    if "%vtype%"=="" set "vtype=pd-standard"
    
    gcloud compute disks describe "%vname%" --zone="%zone%" >nul 2>&1
    if not errorlevel 1 (
        echo Volume '%vname%' already exists in zone %zone%
        exit /b 0
    )

    set "cmd=gcloud compute disks create "%vname%" --size="%size%GB" --zone="%zone%" --type="%vtype%""
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        set "cmd=!cmd! --labels="%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%""
    )
    %cmd%
) else if "%provider%"=="azure" (
    if "%vtype%"=="" set "vtype=Standard_LRS"
    if "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"=="" (
        echo Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations. >&2
        exit /b 1
    )
    
    az disk show --name "%vname%" --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%" >nul 2>&1
    if not errorlevel 1 (
        echo Volume '%vname%' already exists in resource group %LIBSCRIPT_AZURE_RESOURCE_GROUP%
        exit /b 0
    )

    set "cmd=az disk create --name "%vname%" --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%" --location "%zone%" --size-gb "%size%" --sku "%vtype%""
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        set "cmd=!cmd! --tags "%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%""
    )
    %cmd%
)
exit /b 0

:: ## libscript_volume_delete
:: Executes libscript_volume_delete functionality.
:libscript_volume_delete
set "provider=%~2"
set "vid=%~3"

if "%provider%"=="aws" (
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed aws volume "%vid%"
        if errorlevel 1 exit /b 1
    )
    aws ec2 delete-volume --volume-id "%vid%"
) else if "%provider%"=="gcp" (
    if "%LIBSCRIPT_VOLUME_ZONE%"=="" (
        echo Error: --zone ^(or LIBSCRIPT_VOLUME_ZONE^) is required for GCP delete. >&2
        exit /b 1
    )
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed gcp volume "%vid%" "%LIBSCRIPT_VOLUME_ZONE%"
        if errorlevel 1 exit /b 1
    )
    gcloud compute disks delete "%vid%" --zone="%LIBSCRIPT_VOLUME_ZONE%" --quiet
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"=="" (
        echo Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations. >&2
        exit /b 1
    )
    if exist "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" (
        call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :libscript_verify_managed azure volume "%vid%" "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"
        if errorlevel 1 exit /b 1
    )
    az disk delete --name "%vid%" --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%" --yes
)
exit /b 0

:: ## libscript_volume_list
:: Executes libscript_volume_list functionality.
:libscript_volume_list
set "provider=%~2"
call "%LIBSCRIPT_ROOT_DIR%\_lib\cloud\core\tags.cmd" :init

if "%provider%"=="aws" (
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        aws ec2 describe-volumes --filters "Name=tag:%LIBSCRIPT_TAG_KEY%,Values=%LIBSCRIPT_TAG_VALUE%" --query "Volumes[*].[VolumeId,State,Attachments[0].State]" --output table
    ) else (
        aws ec2 describe-volumes --query "Volumes[*].[VolumeId,State,Attachments[0].State]" --output table
    )
) else if "%provider%"=="gcp" (
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        gcloud compute disks list --filter="labels.%LIBSCRIPT_TAG_KEY%=%LIBSCRIPT_TAG_VALUE%"
    ) else (
        gcloud compute disks list
    )
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"=="" (
        echo Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations. >&2
        exit /b 1
    )
    if "%LIBSCRIPT_TAG_ENABLE%"=="true" (
        az disk list --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%" --query "[?tags.%LIBSCRIPT_TAG_KEY% == '%LIBSCRIPT_TAG_VALUE%'].[name,diskState]" --output tsv
    ) else (
        az disk list --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%" --query "[].[name,diskState]" --output tsv
    )
)
exit /b 0

:: ## libscript_volume_attach
:: Executes libscript_volume_attach functionality.
:libscript_volume_attach
set "provider=%~2"
set "vid=%~3"
set "nid=%~4"
set "device=%~5"

if "%nid%"=="" (
    echo Error: --node-id and --device are required for attach. >&2
    exit /b 1
)
if "%device%"=="" (
    echo Error: --node-id and --device are required for attach. >&2
    exit /b 1
)

if "%provider%"=="aws" (
    aws ec2 attach-volume --volume-id "%vid%" --instance-id "%nid%" --device "%device%"
) else if "%provider%"=="gcp" (
    if "%LIBSCRIPT_VOLUME_ZONE%"=="" (
        echo Error: --zone is required for GCP attach. >&2
        exit /b 1
    )
    gcloud compute instances attach-disk "%nid%" --disk "%vid%" --device-name "%device%" --zone "%LIBSCRIPT_VOLUME_ZONE%"
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"=="" (
        echo Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations. >&2
        exit /b 1
    )
    az vm disk attach --vm-name "%nid%" --name "%vid%" --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%" --new false
)
exit /b 0

:: ## libscript_volume_detach
:: Executes libscript_volume_detach functionality.
:libscript_volume_detach
set "provider=%~2"
set "vid=%~3"
set "nid=%~4"

if "%nid%"=="" (
    echo Error: --node-id is required for detach. >&2
    exit /b 1
)

if "%provider%"=="aws" (
    aws ec2 detach-volume --volume-id "%vid%" --instance-id "%nid%"
) else if "%provider%"=="gcp" (
    if "%LIBSCRIPT_VOLUME_ZONE%"=="" (
        echo Error: --zone is required for GCP detach. >&2
        exit /b 1
    )
    gcloud compute instances detach-disk "%nid%" --disk "%vid%" --zone "%LIBSCRIPT_VOLUME_ZONE%"
) else if "%provider%"=="azure" (
    if "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"=="" (
        echo Error: LIBSCRIPT_AZURE_RESOURCE_GROUP must be set for Azure operations. >&2
        exit /b 1
    )
    az vm disk detach --vm-name "%nid%" --name "%vid%" --resource-group "%LIBSCRIPT_AZURE_RESOURCE_GROUP%"
)
exit /b 0
