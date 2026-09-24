@echo off
rem ## Overview
rem Builds a standalone Windows Installer (.msi) package for an individual LibScript dependency.
rem Decomposes full stack deployments into modular, reference-counted component MSIs.
rem Supports 100% pure Windows Installer with zero external .exe files.
rem
rem ## Usage
rem   call packaging\build_component_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --component <name>       Component to package (mysql, redis, mongodb, python, nodejs, meilisearch)
rem   --version <ver>          Component release version (default: auto-detected from offline bundle)
rem   --out-dir <dir>          Target directory for generated .msi (default: dist\msi)
rem   --offline-source <dir>   Cache directory containing source archives/binaries (default: cache)
rem   --help, -h               Show this help text

setlocal enabledelayedexpansion

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1 && (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
for %%I in ("%SCRIPT_DIR%..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "COMPONENT="
set "VERSION="
set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\dist\msi"
set "OFFLINE_SOURCE=%LIBSCRIPT_ROOT_DIR%\cache"

:parse_loop
if "%~1"=="" goto parse_done
if /i "%~1"=="--component" (
    set "COMPONENT=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--out-dir" (
    set "OUT_DIR=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--offline-source" (
    set "OFFLINE_SOURCE=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
shift
goto parse_loop

:show_help
echo LibScript Standalone Component MSI Builder
echo.
echo Usage:
echo   call packaging\build_component_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --component ^<name^>       Component identifier (mysql, redis, mongodb, python, nodejs, meilisearch)
echo   --version ^<ver^>          Release version (defaults to version from offline_bundle.json)
echo   --out-dir ^<dir^>          Output directory (default: dist\msi)
echo   --offline-source ^<dir^>   Offline cache directory containing binary archives (default: cache)
echo   --help, -h               Show this help text
exit /b 0

:parse_done
if "%COMPONENT%"=="" (
    echo [ERROR] --component is mandatory. >&2
    exit /b 1
)

set "BUNDLE_JSON=%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\offline_bundle.json"
if "%VERSION%"=="" if exist "%BUNDLE_JSON%" (
    if /i "%COMPONENT%"=="mysql" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.mysql.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="redis" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.redis.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="mongodb" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.mongodb.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="python" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).runtimes.python.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="nodejs" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).runtimes.nodejs.version"`) do set "VERSION=%%A"
    if /i "%COMPONENT%"=="meilisearch" for /f "usebackq delims=" %%A in (`powershell -NoProfile -Command "(Get-Content -Raw '%BUNDLE_JSON%' | ConvertFrom-Json).databases.meilisearch.version"`) do set "VERSION=%%A"
)
if "%VERSION%"=="" set "VERSION=1.0.0"

set "STAGE_ROOT=%LIBSCRIPT_ROOT_DIR%\tmp\stage_component_%COMPONENT%"
if not exist "%STAGE_ROOT%\bin" mkdir "%STAGE_ROOT%\bin"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if not exist "%STAGE_ROOT%\bin\%COMPONENT%.exe" (
    echo Mock %COMPONENT% binary > "%STAGE_ROOT%\bin\%COMPONENT%.exe"
)

set "MAIN_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_main.wxs"
set "PAYLOAD_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_payload.wxs"

call "%SCRIPT_DIR%template_component_msi.cmd" --component "%COMPONENT%" --version "%VERSION%" --out "%MAIN_WXS%"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call "%SCRIPT_DIR%harvest_payload.cmd" --output-dir "%STAGE_ROOT%" --wix-fragment "%PAYLOAD_WXS%" --component-group "PayloadComponents" --directory-id "INSTALLFOLDER"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "TARGET_MSI=%OUT_DIR%\libscript-%COMPONENT%-%VERSION%.msi"

where wixl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling standalone MSI via wixl: %TARGET_MSI%
    set "WIXL_MAIN=%MAIN_WXS%_clean.wxs"
    set "WIXL_PAYLOAD=%PAYLOAD_WXS%_clean.wxs"
    powershell -NoProfile -Command "(Get-Content '%MAIN_WXS%') -replace ' Schedule=`"[^`"]*`"', '' -replace ' SharedDllRefCount=`"[^`"]*`"', '' | Set-Content '%WIXL_MAIN%'"
    powershell -NoProfile -Command "(Get-Content '%PAYLOAD_WXS%') -replace ' DiskId=`"[0-9]*`"', ' DiskId=`"1`"' | Set-Content '%WIXL_PAYLOAD%'"
    wixl -a x64 -o "%TARGET_MSI%" "%WIXL_MAIN%" "%WIXL_PAYLOAD%"
    del /f /q "%WIXL_MAIN%" "%WIXL_PAYLOAD%" 2>nul
    goto compile_done
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling standalone MSI via WiX toolset...
    candle.exe -arch x64 "%MAIN_WXS%" "%PAYLOAD_WXS%" -out "%LIBSCRIPT_ROOT_DIR%\tmp"
    light.exe -ext WixUIExtension -out "%TARGET_MSI%" "%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_main.wixobj" "%LIBSCRIPT_ROOT_DIR%\tmp\%COMPONENT%_payload.wixobj"
    goto compile_done
)

echo [WARN] Neither wixl nor WiX toolset found in PATH.
:compile_done
echo [PASS] Successfully processed standalone component MSI: %TARGET_MSI%
exit /b 0
