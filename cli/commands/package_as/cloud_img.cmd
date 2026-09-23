@echo off
setlocal EnableDelayedExpansion
:: # cloud_img.cmd
::
:: ## Overview
:: Unified public cloud image packaging driver on Windows, dispatching to
:: AWS AMI, Azure VHD, and GCP image builders.
::
:: ## Usage
:: call cli\commands\package_as\cloud_img.cmd [--provider=aws|azure|gcp|all] [input_raw] [out_dir]

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "PROVIDER=all"
set "INPUT=%LIBSCRIPT_ROOT_DIR%\build\target.img"
set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\build\cloud_images"

:parse_loop
if "%~1"=="" goto run_pkg
if /i "%~1"=="--provider=aws" ( set "PROVIDER=aws" & shift & goto parse_loop )
if /i "%~1"=="--provider=azure" ( set "PROVIDER=azure" & shift & goto parse_loop )
if /i "%~1"=="--provider=gcp" ( set "PROVIDER=gcp" & shift & goto parse_loop )
if /i "%~1"=="aws" ( set "PROVIDER=aws" & shift & goto parse_loop )
if /i "%~1"=="azure" ( set "PROVIDER=azure" & shift & goto parse_loop )
if /i "%~1"=="gcp" ( set "PROVIDER=gcp" & shift & goto parse_loop )
if exist "%~1" ( set "INPUT=%~1" & shift & goto parse_loop )
set "OUT_DIR=%~1"
shift
goto parse_loop

:run_pkg
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo [CLOUD-IMG] Packaging cloud images for provider: %PROVIDER%...

if /i "%PROVIDER%"=="all" goto do_all
if /i "%PROVIDER%"=="aws" goto do_aws
if /i "%PROVIDER%"=="azure" goto do_azure
if /i "%PROVIDER%"=="gcp" goto do_gcp

:do_all
call "%SCRIPT_DIR%\aws_ami.cmd" "%INPUT%" "%OUT_DIR%\aws-ebs-root.raw"
call "%SCRIPT_DIR%\azure_vhd.cmd" "%INPUT%" "%OUT_DIR%\disk.vhd"
call "%SCRIPT_DIR%\gcp_image.cmd" "%INPUT%" "%OUT_DIR%\gcp-disk.raw.tar.gz"
goto finish

:do_aws
call "%SCRIPT_DIR%\aws_ami.cmd" "%INPUT%" "%OUT_DIR%\aws-ebs-root.raw"
goto finish

:do_azure
call "%SCRIPT_DIR%\azure_vhd.cmd" "%INPUT%" "%OUT_DIR%\disk.vhd"
goto finish

:do_gcp
call "%SCRIPT_DIR%\gcp_image.cmd" "%INPUT%" "%OUT_DIR%\gcp-disk.raw.tar.gz"
goto finish

:finish
echo [OK] Cloud packaging completed under: %OUT_DIR%
exit /b 0
