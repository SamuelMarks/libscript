@echo off
:: # test_msi_multi_license.cmd
:: ## Overview
:: Validates WiX Windows Installer (.msi) multi-license dialog sequence generation on Windows.
:: ## Usage
:: .\tests\test_msi_multi_license.cmd

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

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays usage instructions and available options.
:show_help
echo Usage: %~nx0
echo Validates WiX Windows Installer (.msi) multi-license dialog sequence generation.
exit /b 0

:: ## main
:: Executes the WiX MSI multi-license manifest verification suite on Windows.
:main
set "TMP_BASE=%TEMP%\test_msi_multi_license_%RANDOM%"
if not exist "!TMP_BASE!" mkdir "!TMP_BASE!"
set "OUT_PREFIX=!TMP_BASE!\wordpress-multi-lic-test"
set "WXS_FILE=!OUT_PREFIX!.wxs"

echo === Generating WordPress .wxs Manifest via packaging\build_msi.cmd ===
call "!LIBSCRIPT_ROOT_DIR!\packaging\build_msi.cmd" "_lib\web-apps\wordpress" --online --out "!OUT_PREFIX!" >nul 2>&1

if not exist "!WXS_FILE!" (
    echo [FAIL] WiX source file was not generated at !WXS_FILE! >&2
    rmdir /s /q "!TMP_BASE!" >nul 2>&1
    exit /b 1
)

call :assert_wxs "Dialog Id=\"Dlg_License\"" "Top-level EULA Dialog exists" || goto :fail
call :assert_wxs "Property=\"LICENSE_ACCEPTED\"" "License acceptance property configured" || goto :fail
call :assert_wxs "Text=\"I Agree\"" "Button text is I Agree instead of Next>" || goto :fail
call :assert_wxs "<Show Dialog=\"Dlg_Welcome\" After=\"CostFinalize\">NOT Installed</Show>" "Welcome dialog shown after CostFinalize" || goto :fail
call :assert_wxs "<Publish Event=\"NewDialog\" Value=\"Dlg_License\">1</Publish>" "License dialog routed from Welcome Next button" || goto :fail
call :assert_wxs "<Publish Event=\"NewDialog\" Value=\"Dlg_SetupType\">1</Publish>" "SetupType dialog routed directly from License I Agree button" || goto :fail
call :assert_wxs "CustomAction Id=\"CA_AbortNoLicense\"" "Unattended install license validation custom action" || goto :fail
call :assert_wxs "AGREE_ALL_LICENSES=\"1\"" "Blanket opt-in property AGREE_ALL_LICENSES supported" || goto :fail
call :assert_wxs "<Custom Action=\"CA_AbortNoLicense\" Before=\"InstallInitialize\">" "License agreement check scheduled before InstallInitialize" || goto :fail

rmdir /s /q "!TMP_BASE!" >nul 2>&1
echo === All WiX MSI multi-license tests passed successfully! ===
exit /b 0

:: ## assert_wxs
:: Asserts that the generated .wxs manifest contains the expected XML substring.
:assert_wxs
set "_NEEDLE=%~1"
set "_DESC=%~2"
findstr /I /C:"!_NEEDLE!" "!WXS_FILE!" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Missing expected WiX element ^(!_DESC!^): !_NEEDLE! >&2
    exit /b 1
)
echo [PASS] !_DESC!
exit /b 0

:: ## fail
:: Cleans up temporary build directory and exits with failure status.
:fail
if exist "!TMP_BASE!" rmdir /s /q "!TMP_BASE!" >nul 2>&1
exit /b 1
