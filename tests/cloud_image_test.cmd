@echo off
setlocal EnableDelayedExpansion
:: # cloud_image_test.cmd
::
:: ## Overview
:: Cloud image geometry and boot milestone verification harness on Windows.
::
:: ## Usage
:: call tests\cloud_image_test.cmd

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
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo [TEST-CLOUD] Starting Cloud Image Geometry Verification on Windows...

set "TEST_DIR=%LIBSCRIPT_ROOT_DIR%\build\test_cloud_verify"
if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%"
if not exist "%TEST_DIR%" mkdir "%TEST_DIR%"

set "RAW_DISK=%TEST_DIR%\raw.img"
echo LibScript Test Disk > "%RAW_DISK%"

call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\azure_vhd.cmd" "%RAW_DISK%" "%TEST_DIR%\azure.vhd" 1
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\gcp_image.cmd" "%RAW_DISK%" "%TEST_DIR%\gcp.tar.gz" 1
call "%LIBSCRIPT_ROOT_DIR%\cli\commands\package_as\aws_ami.cmd" "%RAW_DISK%" "%TEST_DIR%\aws.raw" 1
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\cloud\gen_nocloud_iso.cmd" "test-node" "" "%TEST_DIR%\cidata.iso"

if exist "%TEST_DIR%\azure.vhd" if exist "%TEST_DIR%\gcp.tar.gz" if exist "%TEST_DIR%\aws.raw" if exist "%TEST_DIR%\cidata.iso" (
    echo [PASS] Cloud images and NoCloud ISO verified.
) else (
    echo [FAIL] One or more cloud image artifacts missing. >&2
    exit /b 1
)

if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%"
echo [OK] All cloud image geometries verified successfully on Windows.
exit /b 0
