@echo off
set "THIS_FILE=%~f0"
:: # mfe_helper.cmd
::
:: ## Overview
:: Frontend Micro-Frontend (MFE) build and deployment helper for Open edX on Windows.
:: Manages frontend applications, asset compilation, and static distribution.
::
:: ## Usage
:: Call stacks\cms\openedx\mfe_helper.cmd build <root_dir> <mfe_name> [version]
:: Call stacks\cms\openedx\mfe_helper.cmd deploy <root_dir> <dist_root> <mfe_name> [dest_path]
:: Call stacks\cms\openedx\mfe_helper.cmd list <root_dir>

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 build ^<root_dir^> ^<mfe_name^> [version]
echo        %~nx0 deploy ^<root_dir^> ^<dist_root^> ^<mfe_name^> [dest_path]
echo        %~nx0 list ^<root_dir^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to mfe_helper.ps1.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%mfe_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%mfe_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute MFE helper. >&2
exit /b 1
