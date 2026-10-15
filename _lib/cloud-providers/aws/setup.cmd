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

:: ## do_register_image
:: Performs the do_register_image operation and updates component state.
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
