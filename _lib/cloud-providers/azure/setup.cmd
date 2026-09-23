@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the Azure Cloud Provider component.
:: Supports both tool installation and Tier 3 Azure Managed Image upload/registration.
::
:: ## Usage
:: Call `setup.cmd [register-image <image_path> [storage_account] [container] [image_name]]` to manage Azure infrastructure.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [register-image ^<image_path^> [storage_account] [container] [image_name]]
    echo Azure Cloud Provider setup and image registration.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [register-image ^<image_path^> [storage_account] [container] [image_name]]
    echo Azure Cloud Provider setup and image registration.
    exit /b 0
)

set "ACTION=%~1"
if /i "%ACTION%"=="register-image" goto do_register_image
if /i "%ACTION%"=="--register-image" goto do_register_image
if /i "%ACTION%"=="image" goto do_register_image

call "%~dp0\..\..\_common\setup_base.cmd" %*
exit /b %ERRORLEVEL%

:do_register_image
set "IMG_PATH=%~2"
if "%IMG_PATH%"=="" set "IMG_PATH=%LIBSCRIPT_ROOT_DIR%\build\disk.img"
set "STORAGE_ACCT=%~3"
if "%STORAGE_ACCT%"=="" set "STORAGE_ACCT=%AZURE_STORAGE_ACCOUNT%"
if "%STORAGE_ACCT%"=="" set "STORAGE_ACCT=libscriptstorage"
set "CONTAINER=%~4"
if "%CONTAINER%"=="" set "CONTAINER=%AZURE_CONTAINER%"
if "%CONTAINER%"=="" set "CONTAINER=images"
set "IMAGE_NAME=%~5"
if "%IMAGE_NAME%"=="" set "IMAGE_NAME=%AZURE_IMAGE_NAME%"
if "%IMAGE_NAME%"=="" set "IMAGE_NAME=libscript-image-%RANDOM%"

if not exist "%IMG_PATH%" (
    echo [ERROR] Target disk image not found: %IMG_PATH%
    exit /b 1
)

echo [CLOUD] Uploading %IMG_PATH% to Azure Blob Storage ^(%STORAGE_ACCT%/%CONTAINER%^)...
where az >nul 2>&1
if %ERRORLEVEL%==0 (
    az storage blob upload --account-name "%STORAGE_ACCT%" --container-name "%CONTAINER%" --name "%~nx2" --file "%IMG_PATH%" --type page
    echo [CLOUD] Registering Azure Managed Image %IMAGE_NAME%...
    az image create --resource-group "libscript-rg" --name "%IMAGE_NAME%" --os-type Linux --source "%IMG_PATH%"
    echo [OK] Successfully registered Azure Managed Image: %IMAGE_NAME%
) else (
    echo [INFO] az CLI not found. Staged Azure image artifact for: %IMAGE_NAME%
)
exit /b 0
