@echo off
rem ## Overview
rem Builds the standalone openedx-core.msi Windows Installer package.
rem Packages the LMS and Studio core applications, management CLI, and configuration.
rem Supports lightweight online installer and air-gapped offline installer with pre-bundled dependencies.
rem
rem ## Usage
rem   call packaging\build_openedx_core_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --version <ver>          Package version (default: 22.1.0)
rem   --variant <var>          Installer variant: online, offline, or all (default: all)
rem   --online                 Shorthand for --variant online
rem   --offline                Shorthand for --variant offline
rem   --help, -h               Show this help text

setlocal enabledelayedexpansion

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
for %%I in ("%SCRIPT_DIR%..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "VERSION=22.1.0"
set "VARIANT=all"
set "OUT_FILE="
set "BRANCH="
set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\dist\msi"
set "OFFLINE_SOURCE=%LIBSCRIPT_ROOT_DIR%\cache"
set "HYDRATE=0"
set "ALLOW_MOCK=0"

:: ## parse_loop
:: Iterates over and parses command line arguments.
:parse_loop
if "%~1"=="" goto parse_done
if /i "%~1"=="--version" (
    set "VERSION=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--variant" (
    set "VARIANT=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--online" (
    set "VARIANT=online"
    shift
    goto parse_loop
)
if /i "%~1"=="--offline" (
    set "VARIANT=offline"
    shift
    goto parse_loop
)
if /i "%~1"=="--out" (
    set "OUT_FILE=%~2"
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
if /i "%~1"=="--hydrate" (
    set "HYDRATE=1"
    shift
    goto parse_loop
)
if /i "%~1"=="--allow-mock" (
    set "ALLOW_MOCK=1"
    shift
    goto parse_loop
)
if /i "%~1"=="--branch" (
    set "BRANCH=%~2"
    shift
    shift
    goto parse_loop
)
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
shift
goto parse_loop

:: ## show_help
:: Displays command usage documentation.
:show_help
echo Open edX Core MSI Builder
echo.
echo Usage:
echo   call packaging\build_openedx_core_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --version ^<ver^>          Package version (default: 22.1.0)
echo   --variant ^<var^>          Installer variant (online, offline, or all; default: all)
echo   --online                 Build lightweight online installer
echo   --offline                Build air-gapped offline installer with embedded payload
echo   --out ^<name^>             Output file base name or path
echo   --out-dir ^<dir^>          Output directory (default: dist\msi)
echo   --offline-source ^<dir^>   Offline cache directory containing binary archives (default: cache)
echo   --hydrate                Force hydration of offline cache before building
echo   --allow-mock             Allow fallback to mock assets if offline assets cannot be acquired
echo   --branch ^<name^>          Branch or tag ref (optional)
echo   --help, -h               Show this help text
exit /b 0

:: ## parse_done
:: Stages files and invokes payload harvesting and WiX toolset.
:parse_done
set "BUNDLE_JSON=%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\offline_bundle.json"

if /i "%VARIANT%"=="online" (
    call :build_single_variant online
    exit /b !ERRORLEVEL!
)
if /i "%VARIANT%"=="offline" (
    call :build_single_variant offline
    exit /b !ERRORLEVEL!
)
if /i "%VARIANT%"=="all" (
    call :build_single_variant online
    if !ERRORLEVEL! neq 0 exit /b !ERRORLEVEL!
    call :build_single_variant offline
    exit /b !ERRORLEVEL!
)

echo [ERROR] Unknown variant: %VARIANT%. Use online, offline, or all. >&2
exit /b 1

:: ## build_single_variant
:: Compiles a single Open edX Core variant (online or offline).
::
:: ## Parameters
::   %~1 - Variant ("online" or "offline")
:build_single_variant
set "CURR_VAR=%~1"
set "STAGE_ROOT=%LIBSCRIPT_ROOT_DIR%\tmp\stage_openedx_core_%CURR_VAR%"
if exist "%STAGE_ROOT%" rmdir /s /q "%STAGE_ROOT%" 2>nul
if not exist "%STAGE_ROOT%" mkdir "%STAGE_ROOT%" 2>nul
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul

xcopy /E /I /Y /Q "%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\*" "%STAGE_ROOT%" >nul 2>&1

if /i "%CURR_VAR%"=="offline" (
    set "NEED_HYDRATE=0"
    if not exist "%OFFLINE_SOURCE%\codebase" set "NEED_HYDRATE=1"
    if not exist "%OFFLINE_SOURCE%\wheels" set "NEED_HYDRATE=1"

    if "%HYDRATE%"=="1" set "NEED_HYDRATE=1"
    if "!NEED_HYDRATE!"=="1" if "%ALLOW_MOCK%"=="0" (
        echo [INFO] Hydrating codebase and wheels before building offline core...
        call "%SCRIPT_DIR%hydrate_offline_cache.cmd" --manifest "%BUNDLE_JSON%" --cache-dir "%OFFLINE_SOURCE%" --codebase --wheels
    )

    if exist "%OFFLINE_SOURCE%\codebase" (
        if not exist "%STAGE_ROOT%\codebase" mkdir "%STAGE_ROOT%\codebase" 2>nul
        xcopy /E /I /Y /Q "%OFFLINE_SOURCE%\codebase\*" "%STAGE_ROOT%\codebase" >nul 2>&1
    ) else if "%ALLOW_MOCK%"=="1" (
        if not exist "%STAGE_ROOT%\codebase" mkdir "%STAGE_ROOT%\codebase" 2>nul
        echo Mock Open edX codebase archive > "%STAGE_ROOT%\codebase\mock_codebase.zip"
    )

    if exist "%OFFLINE_SOURCE%\wheels" (
        if not exist "%STAGE_ROOT%\wheels" mkdir "%STAGE_ROOT%\wheels" 2>nul
        xcopy /E /I /Y /Q "%OFFLINE_SOURCE%\wheels\*" "%STAGE_ROOT%\wheels" >nul 2>&1
    ) else if "%ALLOW_MOCK%"=="1" (
        if not exist "%STAGE_ROOT%\wheels" mkdir "%STAGE_ROOT%\wheels" 2>nul
        echo Mock wheel package > "%STAGE_ROOT%\wheels\mock_wheel.whl"
    )
)

set "MAIN_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_%CURR_VAR%_main.wxs"
set "PAYLOAD_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_%CURR_VAR%_payload.wxs"

call "%SCRIPT_DIR%template_openedx_core_msi.cmd" --version "%VERSION%" --variant "%CURR_VAR%" --out "%MAIN_WXS%"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call "%SCRIPT_DIR%harvest_payload.cmd" --source-dir "%STAGE_ROOT%" --wix-fragment "%PAYLOAD_WXS%" --component-group "OpenEdXCorePayloadComponents" --directory-id "INSTALLFOLDER"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

if defined OUT_FILE (
    set "TARGET_MSI=%OUT_FILE%"
    if /i "!TARGET_MSI:~-4!"==".msi" set "TARGET_MSI=!TARGET_MSI:~0,-4!"
    if /i "%VARIANT%"=="all" (
        if /i "%CURR_VAR%"=="offline" (
            set "TARGET_MSI=!TARGET_MSI!-offline.msi"
        ) else (
            set "TARGET_MSI=!TARGET_MSI!.msi"
        )
    ) else (
        set "TARGET_MSI=!TARGET_MSI!.msi"
    )
) else (
    if /i "%CURR_VAR%"=="offline" (
        set "TARGET_MSI=%OUT_DIR%\openedx-core-offline-%VERSION%.msi"
    ) else (
        set "TARGET_MSI=%OUT_DIR%\openedx-core-%VERSION%.msi"
    )
)

for %%I in ("%TARGET_MSI%") do (
    if not exist "%%~dpI" mkdir "%%~dpI" 2>nul
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% neq 0 if exist "%LIBSCRIPT_ROOT_DIR%\tools\wix\candle.exe" (
    set "PATH=%LIBSCRIPT_ROOT_DIR%\tools\wix;!PATH!"
)

where wixl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Open edX Core %CURR_VAR% MSI via wixl: %TARGET_MSI%
    set "WIXL_MAIN=%MAIN_WXS%_clean.wxs"
    set "WIXL_PAYLOAD=%PAYLOAD_WXS%_clean.wxs"
    powershell -NoProfile -Command "(Get-Content '%MAIN_WXS%') -replace ' Schedule=`"[^`"]*`"', '' -replace ' Permanent=`"[^`"]*`"', '' -replace ' NeverOverwrite=`"[^`"]*`"', '' | Set-Content '%WIXL_MAIN%'"
    powershell -NoProfile -Command "(Get-Content '%PAYLOAD_WXS%') -replace ' DiskId=`"[0-9]*`"', ' DiskId=`"1`"' | Set-Content '%WIXL_PAYLOAD%'"
    wixl -a x64 -o "%TARGET_MSI%" "%WIXL_MAIN%" "%WIXL_PAYLOAD%"
    set "WIXL_EXIT=!ERRORLEVEL!"
    del /f /q "%WIXL_MAIN%" "%WIXL_PAYLOAD%" 2>nul
    if !WIXL_EXIT! neq 0 (
        echo [ERROR] wixl compilation failed for Open edX Core %CURR_VAR%. >&2
        exit /b !WIXL_EXIT!
    )
    goto compile_done
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Open edX Core %CURR_VAR% MSI via WiX toolset...
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_%CURR_VAR%_main.wixobj" "%MAIN_WXS%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX candle compilation failed for %MAIN_WXS%. >&2
        exit /b !ERRORLEVEL!
    )
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_%CURR_VAR%_payload.wixobj" "%PAYLOAD_WXS%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX candle compilation failed for %PAYLOAD_WXS%. >&2
        exit /b !ERRORLEVEL!
    )
    light.exe -nologo -sval -ext WixUIExtension -out "%TARGET_MSI%" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_%CURR_VAR%_main.wixobj" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_%CURR_VAR%_payload.wixobj"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX light linking failed for Open edX Core %CURR_VAR%. >&2
        exit /b !ERRORLEVEL!
    )
    goto compile_done
)

echo [WARN] Neither wixl nor WiX toolset found in PATH.

:: ## compile_done
:: Validates generated MSI package and synchronizes into output directory.
:compile_done
if not exist "%TARGET_MSI%" (
    echo [ERROR] Target Open edX Core MSI was not generated: %TARGET_MSI% >&2
    exit /b 1
)
for %%I in ("%TARGET_MSI%") do (
    if /i not "%%~dpI"=="%OUT_DIR%" (
        if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul
        copy /y "%TARGET_MSI%" "%OUT_DIR%" >nul 2>&1
    )
)
echo [PASS] Successfully built Open edX Core MSI (%CURR_VAR%): %TARGET_MSI%
exit /b 0
