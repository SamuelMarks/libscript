@echo off
:: # test_msi_generation.cmd
::
:: ## Overview
:: Unit and integration test for WiX MSI installer generation on Windows.
::
:: ## Usage
:: tests\test_msi_generation.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2^>^&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" ^>^&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_msi_cmd_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%"

echo === Testing WiX MSI Installer Generation on Windows ===

echo LibScript Test License Agreement > "%TEST_TMP_DIR%\LICENSE.txt"
type nul > "%TEST_TMP_DIR%\test_icon.ico"
type nul > "%TEST_TMP_DIR%\test_banner_top.bmp"
type nul > "%TEST_TMP_DIR%\test_banner_side.bmp"

set "OUT_FILE=%TEST_TMP_DIR%\TestPackage"
set "APP_NAME=TestStack"
set "APP_VERSION=1.0.0.0"
set "APP_PUBLISHER=LibScriptTest"
set "PRODUCT_CODE=*"
set "UPGRADE_CODE=12345678-1234-5678-1234-567812345678"
set "install_scope=perMachine"
set "WELCOME_TEXT=Welcome to TestStack"
set "ICON_PATH=%TEST_TMP_DIR%\test_icon.ico"
set "BANNER_TOP_PATH=%TEST_TMP_DIR%\test_banner_top.bmp"
set "BANNER_SIDE_PATH=%TEST_TMP_DIR%\test_banner_side.bmp"
set "LICENSE_PATH=%TEST_TMP_DIR%\LICENSE.txt"

set "WXS_FILE=%TEST_TMP_DIR%\TestPackage.wxs"
call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd" "%LIBSCRIPT_ROOT_DIR%\_lib\web-apps\wordpress" --out "%WXS_FILE%"

if not exist "%WXS_FILE%" (
    echo [FAIL] Expected .wxs file was not generated
    exit /b 1
)
echo [PASS] Generated %WXS_FILE%

findstr /i "MsiHiddenProperties" "%WXS_FILE%" >nul || (echo [FAIL] Missing MsiHiddenProperties & exit /b 1)
findstr /i "INSTALLFOLDER" "%WXS_FILE%" >nul || (echo [FAIL] Missing INSTALLFOLDER & exit /b 1)

echo [PASS] All Windows WiX assertions passed!
rmdir /s /q "%TEST_TMP_DIR%"
exit /b 0
