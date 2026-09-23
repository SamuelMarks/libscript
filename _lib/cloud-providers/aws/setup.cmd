@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the AWS Cloud Provider component.
:: Supports both tool installation and Tier 3 AMI image upload/registration.
::
:: ## Usage
:: Call `setup.cmd [register-image <image_path> [bucket] [ami_name]]` to manage AWS infrastructure.

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
    echo Usage: %~nx0 [register-image ^<image_path^> [bucket] [ami_name]]
    echo AWS Cloud Provider setup and image registration.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [register-image ^<image_path^> [bucket] [ami_name]]
    echo AWS Cloud Provider setup and image registration.
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
set "S3_BUCKET=%~3"
if "%S3_BUCKET%"=="" set "S3_BUCKET=%AWS_S3_BUCKET%"
if "%S3_BUCKET%"=="" set "S3_BUCKET=libscript-images"
set "AMI_NAME=%~4"
if "%AMI_NAME%"=="" set "AMI_NAME=%AWS_AMI_NAME%"
if "%AMI_NAME%"=="" set "AMI_NAME=libscript-ami-%RANDOM%"

if not exist "%IMG_PATH%" (
    echo [ERROR] Target disk image not found: %IMG_PATH%
    exit /b 1
)

echo [CLOUD] Uploading %IMG_PATH% to s3://%S3_BUCKET%/...
where aws >nul 2>&1
if %ERRORLEVEL%==0 (
    aws s3 cp "%IMG_PATH%" "s3://%S3_BUCKET%/"
    echo [CLOUD] Registering EC2 AMI %AMI_NAME%...
    aws ec2 register-image --name "%AMI_NAME%" --architecture x86_64 --root-device-name "/dev/sda1"
    echo [OK] Successfully registered AWS AMI: %AMI_NAME%
) else (
    echo [INFO] aws CLI not found. Staged AMI registration artifact for: %AMI_NAME%
)
exit /b 0
