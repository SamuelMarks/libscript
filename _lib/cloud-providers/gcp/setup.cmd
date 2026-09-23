@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the GCP Cloud Provider component.
:: Supports both tool installation and Tier 3 GCE custom image upload/registration.
::
:: ## Usage
:: Call `setup.cmd [register-image <image_path> [bucket] [image_name] [accelerator]]` to manage GCP infrastructure.

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
    echo Usage: %~nx0 [register-image ^<image_path^> [bucket] [image_name]]
    echo GCP Cloud Provider setup and custom image registration.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [register-image ^<image_path^> [bucket] [image_name]]
    echo GCP Cloud Provider setup and custom image registration.
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
set "GCS_BUCKET=%~3"
if "%GCS_BUCKET%"=="" set "GCS_BUCKET=%GCP_GCS_BUCKET%"
if "%GCS_BUCKET%"=="" set "GCS_BUCKET=libscript-images"
set "GCE_IMAGE=%~4"
if "%GCE_IMAGE%"=="" set "GCE_IMAGE=%GCP_IMAGE_NAME%"
if "%GCE_IMAGE%"=="" set "GCE_IMAGE=libscript-image-%RANDOM%"

if not exist "%IMG_PATH%" (
    echo [ERROR] Target disk image not found: %IMG_PATH%
    exit /b 1
)

echo [CLOUD] Uploading %IMG_PATH% to gs://%GCS_BUCKET%/...
where gcloud >nul 2>&1
if %ERRORLEVEL%==0 (
    gcloud storage cp "%IMG_PATH%" "gs://%GCS_BUCKET%/"
    echo [CLOUD] Creating custom GCE image %GCE_IMAGE%...
    gcloud compute images create "%GCE_IMAGE%" --source-uri="gs://%GCS_BUCKET%/%~nx2" --labels="managed-by=libscript"
    echo [OK] Successfully registered GCP GCE image: %GCE_IMAGE%
) else (
    echo [INFO] gcloud CLI not found. Staged GCE image artifact for: %GCE_IMAGE%
)
exit /b 0
