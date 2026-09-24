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
rem   --out <name>       Output file base name or path (default: dist\msi\openedx-core-<version>.msi)
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
echo Open edX Core MSI Builder
echo.
echo Usage:
echo   call packaging\build_openedx_core_msi.cmd [OPTIONS]
echo.
echo Options:
echo   --version ^<ver^>    Package version (default: 22.1.0)
echo   --out ^<name^>       Output file base name or path
echo   --out-dir ^<dir^>    Output directory (default: dist\msi)
echo   --branch ^<name^>    Branch or tag ref (optional)
echo   --help, -h         Show this help text
exit /b 0

:: ## parse_done
:: Stages files and invokes payload harvesting and WiX toolset.
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

if defined OUT_FILE (
    set "TARGET_MSI=%OUT_FILE%"
    if /i not "!TARGET_MSI:~-4!"==".msi" set "TARGET_MSI=!TARGET_MSI!.msi"
) else (
    set "TARGET_MSI=%OUT_DIR%\openedx-core-%VERSION%.msi"
)

for %%I in ("%TARGET_MSI%") do (
    if not exist "%%~dpI" mkdir "%%~dpI" 2>nul
)

where wixl >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo [INFO] Compiling Open edX Core MSI via wixl: %TARGET_MSI%
    set "WIXL_MAIN=%MAIN_WXS%_clean.wxs"
    set "WIXL_PAYLOAD=%PAYLOAD_WXS%_clean.wxs"
    powershell -NoProfile -Command "(Get-Content '%MAIN_WXS%') -replace ' Schedule=`"[^`"]*`"', '' -replace ' Permanent=`"[^`"]*`"', '' -replace ' NeverOverwrite=`"[^`"]*`"', '' | Set-Content '%WIXL_MAIN%'"
    powershell -NoProfile -Command "(Get-Content '%PAYLOAD_WXS%') -replace ' DiskId=`"[0-9]*`"', ' DiskId=`"1`"' | Set-Content '%WIXL_PAYLOAD%'"
    wixl -a x64 -o "%TARGET_MSI%" "%WIXL_MAIN%" "%WIXL_PAYLOAD%"
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
    echo [INFO] Compiling Open edX Core MSI via WiX toolset...
    candle.exe -nologo -arch x64 -out "%LIBSCRIPT_ROOT_DIR%\tmp\" "%MAIN_WXS%" "%PAYLOAD_WXS%"
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] WiX candle compilation failed. >&2
        exit /b %ERRORLEVEL%
    )
    light.exe -nologo -sval -ext WixUIExtension -out "%TARGET_MSI%" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_main.wixobj" "%LIBSCRIPT_ROOT_DIR%\tmp\openedx_core_payload.wixobj"
    if %ERRORLEVEL% neq 0 (
        echo [ERROR] WiX light linking failed. >&2
        exit /b %ERRORLEVEL%
    )
    goto compile_done
)

echo [WARN] Neither wixl nor WiX toolset found in PATH.

:: ## compile_done
:: Validates the built MSI output package and syncs to output directory.
:compile_done
if not exist "%TARGET_MSI%" (
    echo [ERROR] Target MSI was not generated: %TARGET_MSI% >&2
    exit /b 1
)
for %%I in ("%TARGET_MSI%") do (
    if /i not "%%~dpI"=="%OUT_DIR%" (
        if not exist "%OUT_DIR%" mkdir "%OUT_DIR%" 2>nul
        copy /y "%TARGET_MSI%" "%OUT_DIR%" >nul 2>&1
    )
)
echo [PASS] Successfully built Open edX Core MSI: %TARGET_MSI%
exit /b 0
