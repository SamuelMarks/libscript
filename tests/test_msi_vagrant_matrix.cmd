@echo off
:: # test_msi_vagrant_matrix.cmd
::
:: ## Overview
:: Unified cross-platform test runner for .msi building, GUI wizard stage verification
:: (quick-install and custom-install flows), window-cropped screenshot validation in
:: ..\cc0-assets\libscript, and ..\bento Vagrant box verification across Windows, Linux,
:: macOS, FreeBSD, and illumos (OmniOS). Uses SamuelMarks/msi-rs across all 5 platforms
:: and restricts optional WiX comparison (--use-wix / --compare-wix) strictly to Windows.
::
:: ## Usage
:: tests/test_msi_vagrant_matrix.cmd [--os <windows|linux|macos|freebsd|illumos|all>] [--target <openedx|wordpress|sqlite|all>] [--use-wix] [--compare-wix] [--live-vagrant]

setlocal EnableDelayedExpansion
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

set "OS_TARGET=all"
set "PKG_TARGET=all"
set "USE_WIX=0"
set "COMPARE_WIX=0"
set "LIVE_VAGRANT=0"

:: ## parse_args
:: Parses command-line options for test_msi_vagrant_matrix.cmd.
:parse_args
if "%~1"=="" goto :run_matrix
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--os" (
    set "OS_TARGET=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--target" (
    set "PKG_TARGET=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--use-wix" (
    set "USE_WIX=1"
    shift
    goto :parse_args
)
if /I "%~1"=="--compare-wix" (
    set "COMPARE_WIX=1"
    shift
    goto :parse_args
)
if /I "%~1"=="--live-vagrant" (
    set "LIVE_VAGRANT=1"
    shift
    goto :parse_args
)
set "PKG_TARGET=%~1"
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for test_msi_vagrant_matrix.cmd.
:show_help
echo Usage: %~nx0 [--os ^<windows^|linux^|macos^|freebsd^|illumos^|all^>] [--target ^<openedx^|wordpress^|sqlite^|all^>] [--use-wix] [--compare-wix] [--live-vagrant]
echo Runs the cross-platform msi-rs build, GUI stage capture, and ..\bento Vagrant test matrix.
exit /b 0

:: ## run_matrix
:: Executes the end-to-end verification pipeline across requested OS and package targets.
:run_matrix
if "!USE_WIX!"=="1" (
    if /I not "!OS_TARGET!"=="windows" if /I not "!OS_TARGET!"=="all" (
        echo [ERROR] WiX only supports Windows; refusing to test WiX on !OS_TARGET!. >&2
        exit /b 1
    )
)
if "!COMPARE_WIX!"=="1" (
    if /I not "!OS_TARGET!"=="windows" if /I not "!OS_TARGET!"=="all" (
        echo [ERROR] WiX only supports Windows; refusing to test WiX on !OS_TARGET!. >&2
        exit /b 1
    )
)

echo ==^> [1/5] Verifying ..\bento Vagrant boxes across all 5 OS families...
call "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd"
if errorlevel 1 exit /b 1

echo ==^> [2/5] Verifying SamuelMarks/msi-rs Tier 1 component...
call "!LIBSCRIPT_ROOT_DIR!\_lib\package-managers\msi-rs\test.cmd"
if errorlevel 1 exit /b 1

echo ==^> [3/5] Capturing window-cropped .msi GUI stages ^(quick-install ^& custom-install^)...
call "!LIBSCRIPT_ROOT_DIR!\devtools\capture_msi_vagrant_matrix.cmd" --target "!PKG_TARGET!" --os "!OS_TARGET!" --variant both --flow both
if errorlevel 1 exit /b 1

echo ==^> [4/5] Validating cropped installer window screenshots in ..\cc0-assets\libscript...
call "!LIBSCRIPT_ROOT_DIR!\devtools\verify_screenshots.cmd" --target "!PKG_TARGET!"
if errorlevel 1 exit /b 1

if "!COMPARE_WIX!"=="1" (
    echo ==^> [4b/5] Running Windows-only differential comparison against WiX...
    call "!LIBSCRIPT_ROOT_DIR!\packaging\compare_msirs_wix.cmd" --target "_lib\web-apps\openedx"
    if errorlevel 1 exit /b 1
)

if "!LIVE_VAGRANT!"=="1" (
    echo ==^> [5/5] Executing live Vagrant guest verification across ..\bento VMs...
    call "!LIBSCRIPT_ROOT_DIR!\tests\test_msi_rs_vagrant.cmd"
    if errorlevel 1 exit /b 1
) else (
    echo ==^> [5/5] Matrix verification complete ^(pass --live-vagrant to boot full guest VMs^).
)

echo [PASS] Cross-platform msi-rs Vagrant matrix succeeded!
exit /b 0
