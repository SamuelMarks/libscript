@echo off
:: # test_openedx_msi.cmd
::
:: ## Overview
:: Integration test for Open edX WiX MSI installer generation on Windows.
:: Verifies dialog definitions, Simple and Advanced modes, and browser launch controls.
::
:: ## Usage
:: call tests\test_openedx_msi.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "SCRIPT_DIR=%~dp0"
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

:: ## find_root
:: Finds the root directory of the libscript repository.
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

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_openedx_msi_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%" >nul 2>&1

echo === Testing Open edX MSI Installer Generation on Windows ===

:: ## prepare_assets
:: Generates mock license and asset placeholders.
echo Mock AGPLv3 Open edX License > "%TEST_TMP_DIR%\LICENSE.txt"
type nul > "%TEST_TMP_DIR%\openedx.ico"
type nul > "%TEST_TMP_DIR%\banner_top.bmp"
type nul > "%TEST_TMP_DIR%\banner_side.bmp"

set "OUT_BASE=%TEST_TMP_DIR%\OpenEdX_Test_Setup"

:: ## run_builder
:: Invokes build_openedx_msi.cmd with test arguments.
call "%LIBSCRIPT_ROOT_DIR%\packaging\build_openedx_msi.cmd" ^
  --out "%OUT_BASE%" ^
  --version "2.4.0.0" ^
  --icon "%TEST_TMP_DIR%\openedx.ico" ^
  --banner-top "%TEST_TMP_DIR%\banner_top.bmp" ^
  --banner-side "%TEST_TMP_DIR%\banner_side.bmp" ^
  --license "%TEST_TMP_DIR%\LICENSE.txt"

set "WXS_FILE=%OUT_BASE%.wxs"
if not exist "%WXS_FILE%" (
    echo [FAIL] Expected WXS manifest was not generated: %WXS_FILE%
    exit /b 1
)
echo [PASS] Generated WiX manifest: %WXS_FILE%

:: ## verify_assertions
:: Verifies critical elements inside the generated WXS manifest.
findstr /C:"Property Id=\"SETUP_MODE\" Value=\"Simple\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing SETUP_MODE Simple & exit /b 1)
echo [PASS] Verified: Default Simple Mode property

findstr /C:"Property Id=\"LAUNCH_BROWSER\" Value=\"1\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing LAUNCH_BROWSER & exit /b 1)
echo [PASS] Verified: Default Launch Browser enabled property

findstr /C:"Property Id=\"PROP_MYSQL_REMOTE_URL\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing PROP_MYSQL_REMOTE_URL & exit /b 1)
echo [PASS] Verified: MySQL DBaaS connection URL property

findstr /C:"Property Id=\"PROP_REDIS_PORT\" Value=\"6379\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing PROP_REDIS_PORT & exit /b 1)
echo [PASS] Verified: Customizable Redis port property

findstr /C:"Property Id=\"PROP_REDIS_URL\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing PROP_REDIS_URL & exit /b 1)
echo [PASS] Verified: Remote Redis connection URI property

findstr /C:"Dialog Id=\"Dlg_SetupType\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_SetupType & exit /b 1)
echo [PASS] Verified: Setup Mode selection dialog

findstr /C:"Dialog Id=\"Dlg_Features\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_Features & exit /b 1)
echo [PASS] Verified: Custom Features and Architecture dialog

findstr /C:"Dialog Id=\"Dlg_OpenEdX_DB\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_OpenEdX_DB & exit /b 1)
echo [PASS] Verified: DBaaS and Relational Database configuration dialog

findstr /C:"Dialog Id=\"Dlg_OpenEdX_CacheSearch\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_OpenEdX_CacheSearch & exit /b 1)
echo [PASS] Verified: Cache and search configuration dialog

findstr /C:"Dialog Id=\"Dlg_Exit\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_Exit & exit /b 1)
echo [PASS] Verified: Exit completion dialog

findstr /C:"Control Id=\"CompPython\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing CompPython & exit /b 1)
echo [PASS] Verified: Explicit Python component display

findstr /C:"Control Id=\"CompNode\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing CompNode & exit /b 1)
echo [PASS] Verified: Explicit Node.js component display

findstr /C:"Control Id=\"CompMeili\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing CompMeili & exit /b 1)
echo [PASS] Verified: Explicit Meilisearch component display

findstr /C:"Control Id=\"CompMySQL\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing CompMySQL & exit /b 1)
echo [PASS] Verified: Explicit MySQL component display

findstr /C:"Control Id=\"CompRedis\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing CompRedis & exit /b 1)
echo [PASS] Verified: Explicit Redis component display

findstr /C:"Control Id=\"LaunchBrowserCheckBox\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing LaunchBrowserCheckBox & exit /b 1)
echo [PASS] Verified: Launch Browser checkbox control

findstr /C:"CustomAction Id=\"CA_LaunchBrowser\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing CA_LaunchBrowser & exit /b 1)
echo [PASS] Verified: Launch Browser custom action

findstr /C:"Dialog Id=\"Dlg_InstallLocation\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_InstallLocation & exit /b 1)
echo [PASS] Verified: Destination folders dialog

findstr /C:"Dialog Id=\"Dlg_RuntimeSelection\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_RuntimeSelection & exit /b 1)
echo [PASS] Verified: Runtime environment selection dialog

findstr /C:"Dialog Id=\"Dlg_OpenEdX_SourceRepo\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Dlg_OpenEdX_SourceRepo & exit /b 1)
echo [PASS] Verified: Source repository and release selection dialog

findstr /C:"MajorUpgrade" "%WXS_FILE%" >nul || (echo [FAIL] Missing MajorUpgrade & exit /b 1)
echo [PASS] Verified: Major upgrade configuration

findstr /C:"Schedule=\"afterInstallInitialize\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing afterInstallInitialize & exit /b 1)
echo [PASS] Verified: Major upgrade scheduling

findstr /C:"Property Id=\"DATAFOLDER\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing DATAFOLDER & exit /b 1)
echo [PASS] Verified: Configurable DATAFOLDER directory

findstr /C:"Property Id=\"LOGSFOLDER\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing LOGSFOLDER & exit /b 1)
echo [PASS] Verified: Configurable LOGSFOLDER directory

findstr /C:"Permanent=\"yes\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing Permanent flag & exit /b 1)
echo [PASS] Verified: Permanent datastore protection

findstr /C:"NeverOverwrite=\"yes\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing NeverOverwrite flag & exit /b 1)
echo [PASS] Verified: NeverOverwrite datastore protection

findstr /C:"PROP_OPENEDX_EDX_PLATFORM_REPOSITORY" "%WXS_FILE%" | findstr "Disabled" >nul || (echo [FAIL] Missing Disabled repository control & exit /b 1)
echo [PASS] Verified: Read-only repository display in MSI GUI

findstr /C:"PROP_OPENEDX_VERSION" "%WXS_FILE%" | findstr "Disabled" >nul || (echo [FAIL] Missing Disabled version control & exit /b 1)
echo [PASS] Verified: Read-only release branch display in MSI GUI

findstr /C:"Property Id=\"MsiHiddenProperties\"" "%WXS_FILE%" >nul || (echo [FAIL] Missing MsiHiddenProperties & exit /b 1)
echo [PASS] Verified: Sensitive parameter masking

:: ## verify_custom_override
:: Verifies build-time repository and branch overrides with local directories and tags.
set "CUSTOM_OUT_BASE=%TEST_TMP_DIR%\OpenEdX_Custom_Override"
call "%LIBSCRIPT_ROOT_DIR%\packaging\build_msi.cmd" stacks\cms\openedx ^
  --out "%CUSTOM_OUT_BASE%" ^
  --repo "C:\local\repos\edx-platform-custom" ^
  --branch "v3.2.1-custom-tag"

set "CUSTOM_WXS=%CUSTOM_OUT_BASE%.wxs"
if not exist "%CUSTOM_WXS%" (
    echo [FAIL] Custom override WXS manifest was not created: %CUSTOM_WXS%
    exit /b 1
)

findstr /C:"Property Id=\"PROP_OPENEDX_EDX_PLATFORM_REPOSITORY\" Value=\"C:\local\repos\edx-platform-custom\"" "%CUSTOM_WXS%" >nul || (echo [FAIL] Build-time repository override missing & exit /b 1)
echo [PASS] Verified: Build-time local repository path override baked into installer

findstr /C:"Property Id=\"PROP_OPENEDX_VERSION\" Value=\"v3.2.1-custom-tag\"" "%CUSTOM_WXS%" >nul || (echo [FAIL] Build-time branch/tag override missing & exit /b 1)
echo [PASS] Verified: Build-time custom branch/tag override baked into installer

:: Cleanup temporary artifacts
rmdir /s /q "%TEST_TMP_DIR%" 2>nul
echo === Open edX MSI Windows tests completed successfully! ===
exit /b 0
