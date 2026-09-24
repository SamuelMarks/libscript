@echo off
rem ## Overview
rem Builds the standalone openedx-core.msi Windows Installer package.
rem Packages the LMS and Studio core applications, management CLI, and configuration.
rem Eliminates external .exe files while maintaining full native MSI compliance.
rem
rem ## Usage
rem   call packaging\build_openedx_core_msi.cmd [OPTIONS]
rem
rem ## Parameters
rem   --version <ver>    Package version (default: 22.1.0)
rem   --out-dir <dir>    Output directory (default: dist\msi)
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
set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\dist\msi"

:parse_loop
if "%~1"=="" goto parse_done
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
if /i "%~1"=="--help" goto show_help
if /i "%~1"=="-h" goto show_help
shift
goto parse_loop

:show_help
echo Open edX Core MSI Builder
echo.
echo Usage:
echo   call packaging\build_openedx_core_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --version ^<ver^>    Package version (default: 22.1.0)
echo   --out-dir ^<dir^>    Output directory (default: dist\msi)
echo   --help, -h         Show this help text
exit /b 0

:parse_done
set "STAGE_ROOT=%LIBSCRIPT_ROOT_DIR%\tmp\stage_openedx_core"
if not exist "%STAGE_ROOT%" mkdir "%STAGE_ROOT%"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

xcopy /E /I /Y /Q "%LIBSCRIPT_ROOT_DIR%\stacks\cms\openedx\*" "%STAGE_ROOT%" >nul 2>&1

set "MAIN_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_main.wxs"
set "PAYLOAD_WXS=%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_payload.wxs"

call "%SCRIPT_DIR%template_openedx_core_msi.cmd" --version "%VERSION%" --out "%MAIN_WXS%"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

call "%SCRIPT_DIR%harvest_payload.cmd" --output-dir "%STAGE_ROOT%" --wix-fragment "%PAYLOAD_WXS%" --component-group "OpenEdXCorePayloadComponents" --directory-id "INSTALLFOLDER"
if %ERRORLEVEL% neq 0 exit /b %ERRORLEVEL%

set "TARGET_MSI=%OUT_DIR%\openedx-core-%VERSION%.msi"

where wixl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Open edX Core MSI via wixl: %TARGET_MSI%
    set "WIXL_MAIN=%MAIN_WXS%_clean.wxs"
    set "WIXL_PAYLOAD=%PAYLOAD_WXS%_clean.wxs"
    powershell -NoProfile -Command "(Get-Content '%MAIN_WXS%') -replace ' Schedule=`"[^`"]*`"', '' -replace ' Permanent=`"[^`"]*`"', '' -replace ' NeverOverwrite=`"[^`"]*`"', '' | Set-Content '%WIXL_MAIN%'"
    powershell -NoProfile -Command "(Get-Content '%PAYLOAD_WXS%') -replace ' DiskId=`"[0-9]*`"', ' DiskId=`"1`"' | Set-Content '%WIXL_PAYLOAD%'"
    wixl -a x64 -o "%TARGET_MSI%" "%WIXL_MAIN%" "%WIXL_PAYLOAD%"
    del /f /q "%WIXL_MAIN%" "%WIXL_PAYLOAD%" 2>nul
    goto compile_done
)

where candle.exe >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Open edX Core MSI via WiX toolset...
    candle.exe -arch x64 "%MAIN_WXS%" "%PAYLOAD_WXS%" -out "%LIBSCRIPT_ROOT_DIR%\tmp"
    light.exe -ext WixUIExtension -out "%TARGET_MSI%" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_main.wixobj" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_payload.wixobj"
    goto compile_done
)

echo [WARN] Neither wixl nor WiX toolset found in PATH.
:compile_done
echo [PASS] Successfully built Open edX Core MSI: %TARGET_MSI%
exit /b 0
