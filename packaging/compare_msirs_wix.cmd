@echo off
:: # compare_msirs_wix.cmd
::
:: ## Overview
:: Builds an installer target with SamuelMarks/msi-rs (default) and compares its
:: MSI tables and structure against the Windows-only WiX Toolset using msiinfo and msidiff.
::
:: ## Usage
:: packaging\compare_msirs_wix.cmd [--target <dir>] [--variant <online|offline>] [--out-dir <dir>]

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

set "TARGET_DIR=_lib\web-apps\openedx"
set "VARIANT=online"
set "OUT_DIR=!LIBSCRIPT_ROOT_DIR!\tmp\compare_msi"

:: ## parse_args
:: Parses command-line options for compare_msirs_wix.cmd.
:parse_args
if "%~1"=="" goto :run_comparison
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--target" (
    set "TARGET_DIR=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--variant" (
    set "VARIANT=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--out-dir" (
    set "OUT_DIR=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--with-windows-vagrant" (
    shift
    goto :parse_args
)
set "TARGET_DIR=%~1"
shift
goto :parse_args

:: ## show_help
:: Prints command-line usage instructions for compare_msirs_wix.cmd.
:show_help
echo Usage: %~nx0 [--target ^<dir^>] [--variant ^<online^|offline^>] [--out-dir ^<dir^>]
echo Builds target MSI with msi-rs and compares against Windows WiX.
exit /b 0

:: ## run_comparison
:: Builds the msi-rs MSI and compares against Windows WiX.
:run_comparison
if exist "%USERPROFILE%\.libscript\msi-rs\default\bin" (
    set "PATH=%USERPROFILE%\.libscript\msi-rs\default\bin;!PATH!"
) else if exist "%USERPROFILE%\.libscript\msi-rs\v0.0.1\bin" (
    set "PATH=%USERPROFILE%\.libscript\msi-rs\v0.0.1\bin;!PATH!"
)

if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"
for %%I in ("!TARGET_DIR!") do set "BASE_NAME=%%~nxI"
set "MSIRS_OUT=!OUT_DIR!\!BASE_NAME!-!VARIANT!-msirs"
set "WIX_OUT=!OUT_DIR!\!BASE_NAME!-!VARIANT!-wix"

echo [INFO] Building !TARGET_DIR! (!VARIANT!) via SamuelMarks/msi-rs...
call "!SCRIPT_DIR!\build_msi.cmd" "!TARGET_DIR!" "--!VARIANT!" --out "!MSIRS_OUT!"
if errorlevel 1 exit /b 1

where msiinfo.exe >nul 2>&1
if not errorlevel 1 (
    msiinfo.exe tables "!MSIRS_OUT!.msi" > "!MSIRS_OUT!.tables.txt" 2>nul
    echo [PASS] Extracted msi-rs tables to !MSIRS_OUT!.tables.txt
)

echo [INFO] Building !TARGET_DIR! (!VARIANT!) via Windows WiX (--use-wix) for A/B comparison...
call "!SCRIPT_DIR!\build_msi.cmd" "!TARGET_DIR!" "--!VARIANT!" --use-wix --out "!WIX_OUT!"
if not errorlevel 1 if exist "!WIX_OUT!.msi" (
    where msiinfo.exe >nul 2>&1
    if not errorlevel 1 (
        msiinfo.exe tables "!WIX_OUT!.msi" > "!WIX_OUT!.tables.txt" 2>nul
    )
    where msidiff.exe >nul 2>&1
    if not errorlevel 1 (
        msidiff.exe "!MSIRS_OUT!.msi" "!WIX_OUT!.msi" > "!OUT_DIR!\!BASE_NAME!-!VARIANT!-msidiff.txt" 2>&1
        echo [PASS] Generated msidiff report at !OUT_DIR!\!BASE_NAME!-!VARIANT!-msidiff.txt
    )
)
exit /b 0
