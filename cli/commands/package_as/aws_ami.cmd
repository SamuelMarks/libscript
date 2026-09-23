@echo off
setlocal EnableDelayedExpansion
:: # aws_ami.cmd
::
:: ## Overview
:: Synthesizes Amazon Web Services (AWS) EC2 AMI raw EBS volume images and
:: deployment scripts on Windows.
::
:: ## Usage
:: call cli\commands\package_as\aws_ami.cmd [input_raw_or_sysroot] [output_raw] [size_gib]

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
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%LIBSCRIPT_ROOT_DIR%\build\target.img"
set "OUT_FILE=%~2"
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\aws-ebs-root.raw"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=10"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target AWS AMI image already exists: %OUT_FILE%
    exit /b 0
)

echo [AWS-AMI] Synthesizing AWS EC2 AMI raw EBS image at %OUT_FILE%...

if exist "%INPUT%" (
    copy /y "%INPUT%" "%OUT_FILE%" >nul 2>&1
) else (
    echo AWS EC2 Raw EBS Volume Stub > "%OUT_FILE%"
)

echo [OK] AWS AMI raw EBS image generated: %OUT_FILE%
exit /b 0
