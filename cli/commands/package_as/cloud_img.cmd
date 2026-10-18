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
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("!SCRIPT_DIR!\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "PROVIDER=all"
set "INPUT=!LIBSCRIPT_ROOT_DIR!\build\target.img"
set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\build\cloud_images"

:: ## parse_loop
:: Parses command-line arguments and populates configuration variables.
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

:: ## run_pkg
:: Performs the run_pkg operation and updates component state.
:run_pkg
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

echo [CLOUD-IMG] Packaging cloud images for provider: %PROVIDER%...

if /i "%PROVIDER%"=="all" goto do_all
if /i "%PROVIDER%"=="aws" goto do_aws
if /i "%PROVIDER%"=="azure" goto do_azure
if /i "%PROVIDER%"=="gcp" goto do_gcp

:: ## do_all
:: Performs the do_all operation and updates component state.
:do_all
call "!SCRIPT_DIR!\aws_ami.cmd" "%INPUT%" "%OUT_DIR%\aws-ebs-root.raw"
call "!SCRIPT_DIR!\azure_vhd.cmd" "%INPUT%" "%OUT_DIR%\disk.vhd"
call "!SCRIPT_DIR!\gcp_image.cmd" "%INPUT%" "%OUT_DIR%\gcp-disk.raw.tar.gz"
goto finish

:: ## do_aws
:: Performs the do_aws operation and updates component state.
:do_aws
call "!SCRIPT_DIR!\aws_ami.cmd" "%INPUT%" "%OUT_DIR%\aws-ebs-root.raw"
goto finish

:: ## do_azure
:: Performs the do_azure operation and updates component state.
:do_azure
call "!SCRIPT_DIR!\azure_vhd.cmd" "%INPUT%" "%OUT_DIR%\disk.vhd"
goto finish

:: ## do_gcp
:: Performs the do_gcp operation and updates component state.
:do_gcp
call "!SCRIPT_DIR!\gcp_image.cmd" "%INPUT%" "%OUT_DIR%\gcp-disk.raw.tar.gz"
goto finish

:: ## finish
:: Performs the finish operation and updates component state.
:finish
echo [OK] Cloud packaging completed under: %OUT_DIR%
exit /b 0
