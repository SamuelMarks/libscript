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
for %%V in (group project network firewall node storage dns auth location) do (
    if /i "%~1"=="%%V" (
        set "STACK="
        call "!SCRIPT_DIR!\setup_generic.cmd" %*
        exit /b !ERRORLEVEL!
    )
)
if /i "%ACTION%"=="register-image" goto do_register_image
if /i "%ACTION%"=="--register-image" goto do_register_image
if /i "%ACTION%"=="image" goto do_register_image

call "%~dp0\..\..\_common\setup_base.cmd" %*
exit /b %ERRORLEVEL%

:: ## do_register_image
:: Performs the do_register_image operation and updates component state.
:do_register_image
set "IMG_PATH=%~2"
if "%IMG_PATH%"=="" set "IMG_PATH=!LIBSCRIPT_ROOT_DIR!\build\disk.img"
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
