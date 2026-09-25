@echo off
rem ## Overview
rem Builds the unified Open edX Master Orchestrator Windows Installer (.msi) package.
rem Supports both the online installer and the air-gapped offline installer.
rem Embeds and chains component MSIs with ZERO external .exe files.
rem
rem ## Usage
rem   call packaging\build_openedx_orchestrator_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --version <ver>    Stack release version (default: 22.1.0)
rem   --variant <var>    Installer variant: online, offline, or all (default: all)
rem   --out <name>       Output file base name or path (default: dist\msi\openedx-<version>.msi)
rem   --out-dir <dir>    Output directory (default: dist\msi)
rem   --branch <name>    Branch or tag ref (optional)
rem   --help, -h         Show this help text

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

set "VERSION=22.1.0"
set "VARIANT=all"
set "OUT_FILE="
set "BRANCH="
set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\dist\msi"

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
echo Open edX Master Orchestrator MSI Builder
echo.
echo Usage:
echo   call packaging\build_openedx_orchestrator_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --version ^<ver^>    Stack release version (default: 22.1.0)
echo   --variant ^<var^>    Installer variant (online, offline, or all; default: all)
echo   --out ^<name^>       Output file base name or path
echo   --out-dir ^<dir^>    Output directory for built MSIs (default: dist\msi)
echo   --branch ^<name^>    Branch or tag ref (optional)
echo   --help, -h         Show this help text
exit /b 0

:: ## parse_done
:: Dispatches variant builds according to configuration.
:parse_done
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if /i "%VARIANT%"=="online" (
    call :build_single_variant online
    exit /b %ERRORLEVEL%
)
if /i "%VARIANT%"=="offline" (
    call :build_single_variant offline
    exit /b %ERRORLEVEL%
)
if /i "%VARIANT%"=="all" (
    call :build_single_variant online
    if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%
    call :build_single_variant offline
    exit /b %ERRORLEVEL%
)

echo [ERROR] Unknown variant: %VARIANT%. Use online, offline, or all. >&2
exit /b 1

:: -----------------------------------------------------------------------------
:: ## build_single_variant
:: Compiles an individual Open edX orchestrator variant.
:: Parameters:
::   %~1 - Variant identifier (online or offline)
:build_single_variant
set "CURR_VAR=%~1"
set "STAGE=%LIBSCRIPT_ROOT_DIR%\tmp\stage_orchestrator_%CURR_VAR%"
if exist "%STAGE%" rd /s /q "%STAGE%" >nul 2>&1
if not exist "%STAGE%\bundle" mkdir "%STAGE%\bundle" >nul 2>&1

if /i "%CURR_VAR%"=="offline" (
    xcopy /Y /Q "%OUT_DIR%\libscript-*.msi" "%STAGE%\bundle" >nul 2>&1
    xcopy /Y /Q "%OUT_DIR%\openedx-core-*.msi" "%STAGE%\bundle" >nul 2>&1
)

set "MAIN_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\openedx_orch_%CURR_VAR%_main.wxs"
set "PAYLOAD_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\openedx_orch_%CURR_VAR%_payload.wxs"

call "%SCRIPT_DIR%template_openedx_orchestrator.cmd" --version "%VERSION%" --variant "%CURR_VAR%" --msi-dir "%OUT_DIR%" --out "%MAIN_WXS%"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call "%SCRIPT_DIR%harvest_payload.cmd" --output-dir "%STAGE%" --wix-fragment "%PAYLOAD_WXS%" --component-group "ChainedMsiPayloads" --directory-id "INSTALLFOLDER"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

if defined OUT_FILE (
    set "TARGET_MSI=%OUT_FILE%"
    if /i not "!TARGET_MSI:~-4!"==".msi" set "TARGET_MSI=!TARGET_MSI!.msi"
    if /i "%VARIANT%"=="all" if /i "%CURR_VAR%"=="offline" (
        set "TARGET_MSI=!TARGET_MSI:~0,-4!-offline.msi"
    )
) else (
    set "TARGET_MSI=%OUT_DIR%\openedx-%VERSION%.msi"
    if /i "%CURR_VAR%"=="offline" set "TARGET_MSI=%OUT_DIR%\openedx-offline-%VERSION%.msi"
)

for %%I in ("!TARGET_MSI!") do (
    if not exist "%%~dpI" mkdir "%%~dpI" 2>nul
)

where wixl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Orchestrator MSI %CURR_VAR% via wixl: !TARGET_MSI!
    set "WIXL_MAIN=%MAIN_WXS%_clean.wxs"
    set "WIXL_PAYLOAD=%PAYLOAD_WXS%_clean.wxs"
    powershell -NoProfile -Command "(Get-Content '%MAIN_WXS%') -replace ' Schedule=`"[^`"]*`"', '' | Set-Content '%WIXL_MAIN%'"
    powershell -NoProfile -Command "(Get-Content '%PAYLOAD_WXS%') -replace ' DiskId=`"[0-9]*`"', ' DiskId=`"1`"' | Set-Content '%WIXL_PAYLOAD%'"
    wixl -a x64 -o "!TARGET_MSI!" "%WIXL_MAIN%" "%WIXL_PAYLOAD%"
    set "WIXL_EXIT=!ERRORLEVEL!"
    del /f /q "%WIXL_MAIN%" "%WIXL_PAYLOAD%" 2>nul
    if !WIXL_EXIT! neq 0 (
        echo [ERROR] wixl compilation failed. >&2
        exit /b !WIXL_EXIT!
    )
    goto compile_done
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Orchestrator MSI %CURR_VAR% via WiX toolset...
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_orch_%CURR_VAR%_main.wixobj" "%MAIN_WXS%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX candle compilation failed for %MAIN_WXS%. >&2
        exit /b !ERRORLEVEL!
    )
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_orch_%CURR_VAR%_payload.wixobj" "%PAYLOAD_WXS%"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX candle compilation failed for %PAYLOAD_WXS%. >&2
        exit /b !ERRORLEVEL!
    )
    light.exe -nologo -sval -ext WixUIExtension -out "!TARGET_MSI!" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_orch_%CURR_VAR%_main.wixobj" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_orch_%CURR_VAR%_payload.wixobj"
    if !ERRORLEVEL! neq 0 (
        echo [ERROR] WiX light linking failed. >&2
        exit /b !ERRORLEVEL!
    )
    goto compile_done
)

echo [WARN] Neither wixl nor WiX toolset found in PATH.

:: ## compile_done
:: Verifies target MSI was built and syncs to output directory.
:compile_done
if not exist "!TARGET_MSI!" (
    echo [ERROR] Target MSI was not generated: !TARGET_MSI! >&2
    exit /b 1
)
for %%I in ("!TARGET_MSI!") do (
    if /i not "%%~dpI"=="%OUT_DIR%" (
        if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul
        copy /y "!TARGET_MSI!" "%OUT_DIR%" >nul 2>&1
    )
)
echo [PASS] Successfully built !TARGET_MSI!
exit /b 0
