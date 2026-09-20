@echo off
set "THIS_FILE=%~f0"
:: # health_helper.cmd
::
:: ## Overview
:: Diagnostic healthcheck helper utility for Open edX on Windows.
:: Validates connectivity and responsiveness across databases, caches, and web services.
::
:: ## Usage
:: Call stacks\cms\openedx\health_helper.cmd <is_json> <lms_h> <lms_p> <cms_h> <cms_p> <my_h> <my_p> <mg_h> <mg_p> <rd_h> <rd_p> <me_h> <me_p> <sm_h> <sm_p>

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 ^<is_json^> ^<lms_h^> ^<lms_p^> ^<cms_h^> ^<cms_p^> ^<my_h^> ^<my_p^> ^<mg_h^> ^<mg_p^> ^<rd_h^> ^<rd_p^> ^<me_h^> ^<me_p^> ^<sm_h^> ^<sm_p^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to health_helper.ps1.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%health_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%health_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute healthcheck helper. >&2
exit /b 1
