@echo off
:: # build.cmd
::
:: ## Overview
:: Compiles online and offline Windows Installer (.msi) packages for Open edX using native Windows Batch and WiX candle.exe/light.exe without PowerShell.
::
:: ## Usage
:: build.cmd [--out-dir <dir>] [--online-only | --offline-only]

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

set "OUT_DIR=!SCRIPT_DIR!"
set "MODE=all"

:: ## parse_args
:: Parses CLI flags for MSI compilation.
:parse_args
if "%~1"=="" goto :args_done
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
if /I "%~1"=="--out-dir" (
    set "OUT_DIR=%~2"
    shift
    shift
    goto :parse_args
)
if /I "%~1"=="--online-only" (
    set "MODE=online"
    shift
    goto :parse_args
)
if /I "%~1"=="--offline-only" (
    set "MODE=offline"
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## show_help
:: Displays command-line usage instructions for the MSI build script.
:show_help
echo Usage: %~nx0 [--out-dir ^<dir^>] [--online-only ^| --offline-only]
echo Compiles OpenEdX-Setup.msi and OpenEdX-Setup-Offline.msi via WiX Toolset.
exit /b 0

:: ## args_done
:: Configures WiX PATH isolation and dispatches online/offline compilation.
:args_done
set "WIX_HOME=%LIBSCRIPT_HOME%\wix\3.14\bin"
if "%LIBSCRIPT_HOME%"=="" set "WIX_HOME=%USERPROFILE%\.libscript\wix\3.14\bin"
if exist "!WIX_HOME!" set "PATH=!WIX_HOME!;!PATH!"

if not exist "!OUT_DIR!" mkdir "!OUT_DIR!"

if /I "!MODE!"=="all" (
    call :compile_wxs_pair "OpenEdX-Setup" || exit /b 1
    call :compile_wxs_pair "OpenEdX-Setup-Offline" || exit /b 1
) else if /I "!MODE!"=="online" (
    call :compile_wxs_pair "OpenEdX-Setup" || exit /b 1
) else if /I "!MODE!"=="offline" (
    call :compile_wxs_pair "OpenEdX-Setup-Offline" || exit /b 1
)

echo [OK] MSI compilation workflow completed in !OUT_DIR!
exit /b 0

:: ## compile_wxs_pair
:: Compiles a main and payload WiX source pair into an MSI installer package.
:compile_wxs_pair
set "BASE_NAME=%~1"
set "MAIN_WXS=!SCRIPT_DIR!\!BASE_NAME!.wxs"
set "PAYLOAD_WXS=!SCRIPT_DIR!\!BASE_NAME!_payload.wxs"
set "OUT_MSI=!OUT_DIR!\!BASE_NAME!.msi"

if not exist "!MAIN_WXS!" (
    echo [INFO] Source !MAIN_WXS! not present; delegating to build_msi.cmd...
    if /I "!BASE_NAME!"=="OpenEdX-Setup-Offline" (
        call "!SCRIPT_DIR!\build_msi.cmd" --offline --out-dir "!OUT_DIR!"
        exit /b !ERRORLEVEL!
    ) else (
        call "!SCRIPT_DIR!\build_msi.cmd" --online --out-dir "!OUT_DIR!"
        exit /b !ERRORLEVEL!
    )
)

where candle.exe >nul 2>&1
if errorlevel 1 (
    echo [ERROR] candle.exe not found on PATH. Install wix via libscript.cmd install wix. 1>&2
    exit /b 1
)

pushd "!SCRIPT_DIR!"
echo [INFO] Building !OUT_MSI!...
candle.exe -nologo -out "!BASE_NAME!.wixobj" "!BASE_NAME!.wxs"
if errorlevel 1 (
    popd
    exit /b 1
)
if exist "!PAYLOAD_WXS!" (
    candle.exe -nologo -out "!BASE_NAME!_payload.wixobj" "!BASE_NAME!_payload.wxs"
    if errorlevel 1 (
        popd
        exit /b 1
    )
    light.exe -nologo -sval -ext WixUIExtension -out "!OUT_MSI!" "!BASE_NAME!.wixobj" "!BASE_NAME!_payload.wixobj"
) else (
    light.exe -nologo -sval -ext WixUIExtension -out "!OUT_MSI!" "!BASE_NAME!.wixobj"
)
set "BUILD_RC=!ERRORLEVEL!"
popd
exit /b !BUILD_RC!
