@echo off
:: # test_packaging_branding.cmd
::
:: ## Overview
:: Unit and integration test for cross-platform packaging branding on Windows.
::
:: ## Usage
:: tests\test_packaging_branding.cmd

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

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_brand_cmd_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%"

echo === Testing Cross-Platform Installer Branding on Windows ===

echo Custom Enterprise License Agreement terms > "%TEST_TMP_DIR%\CUSTOM_LICENSE.txt"
type nul > "%TEST_TMP_DIR%\custom_icon.ico"
type nul > "%TEST_TMP_DIR%\banner_top.bmp"
type nul > "%TEST_TMP_DIR%\banner_side.bmp"

set "APP_NAME=BrandApp"
set "APP_VERSION=2.5.0.0"
set "APP_PUBLISHER=BrandCorp"
set "PRODUCT_CODE=*"
set "UPGRADE_CODE=12345678-1234-5678-1234-567812345678"
set "OUT_FILE=%TEST_TMP_DIR%\BrandApp"
set "ICON_PATH=%TEST_TMP_DIR%\custom_icon.ico"
set "BANNER_TOP_PATH=%TEST_TMP_DIR%\banner_top.bmp"
set "BANNER_SIDE_PATH=%TEST_TMP_DIR%\banner_side.bmp"
set "LICENSE_PATH=%TEST_TMP_DIR%\CUSTOM_LICENSE.txt"

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_inno.cmd" > "%TEST_TMP_DIR%\BrandApp.iss"
findstr /i "WizardImageFile" "%TEST_TMP_DIR%\BrandApp.iss" >nul || (echo [FAIL] Inno missing WizardImageFile & exit /b 1)
findstr /i "LicenseFile" "%TEST_TMP_DIR%\BrandApp.iss" >nul || (echo [FAIL] Inno missing LicenseFile & exit /b 1)
echo [PASS] Windows Inno branding assertions passed

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_nsis.cmd" > "%TEST_TMP_DIR%\BrandApp.nsi"
findstr /i "MUI_HEADERIMAGE_BITMAP" "%TEST_TMP_DIR%\BrandApp.nsi" >nul || (echo [FAIL] NSIS missing MUI_HEADERIMAGE_BITMAP & exit /b 1)
findstr /i "MUI_WELCOMEFINISHPAGE_BITMAP" "%TEST_TMP_DIR%\BrandApp.nsi" >nul || (echo [FAIL] NSIS missing MUI_WELCOMEFINISHPAGE_BITMAP & exit /b 1)
echo [PASS] Windows NSIS branding assertions passed

call "%LIBSCRIPT_ROOT_DIR%\packaging\template_msi.cmd"
findstr /i "WixUIBannerBmp" "%TEST_TMP_DIR%\BrandApp.wxs" >nul || (echo [FAIL] MSI missing WixUIBannerBmp & exit /b 1)
findstr /i "WixUIDialogBmp" "%TEST_TMP_DIR%\BrandApp.wxs" >nul || (echo [FAIL] MSI missing WixUIDialogBmp & exit /b 1)
findstr /i "WixUILicenseRtf" "%TEST_TMP_DIR%\BrandApp.wxs" >nul || (echo [FAIL] MSI missing WixUILicenseRtf & exit /b 1)
echo [PASS] Windows MSI branding assertions passed

echo === All Windows branding tests passed! ===
rmdir /s /q "%TEST_TMP_DIR%"
exit /b 0
