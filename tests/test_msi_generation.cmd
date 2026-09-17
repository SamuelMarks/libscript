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
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

for %%I in ("%SCRIPT_DIR%") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

:: ## find_root_loop
:: Iterates upward through the directory tree looking for libscript.cmd.
:find_root_loop
if exist "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" goto found_root
for %%I in ("%LIBSCRIPT_ROOT_DIR%\..") do set "PARENT_DIR=%%~fI"
if "%PARENT_DIR%"=="%LIBSCRIPT_ROOT_DIR%" goto found_root
set "LIBSCRIPT_ROOT_DIR=%PARENT_DIR%"
goto find_root_loop

:: ## found_root
:: Target label reached once the libscript root directory is located.
:found_root

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

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd"

set "WXS_FILE=%TEST_TMP_DIR%\TestPackage.wxs"
if not exist "%WXS_FILE%" (
    echo [FAIL] Expected .wxs file was not generated
    exit /b 1
)
echo [PASS] Generated %WXS_FILE%

findstr /i "WixUILicenseRtf" "%WXS_FILE%" >nul || (echo [FAIL] Missing WixUILicenseRtf & exit /b 1)
findstr /i "WixUIBannerBmp" "%WXS_FILE%" >nul || (echo [FAIL] Missing WixUIBannerBmp & exit /b 1)
findstr /i "WixUIDialogBmp" "%WXS_FILE%" >nul || (echo [FAIL] Missing WixUIDialogBmp & exit /b 1)
findstr /i "Dlg_License" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_License & exit /b 1)
findstr /i "Dlg_Features" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_Features & exit /b 1)

echo [PASS] All Windows WiX assertions passed!
rmdir /s /q "%TEST_TMP_DIR%"
exit /b 0
