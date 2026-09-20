@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # update_results.cmd
::
:: ## Overview
:: Updates the Supported Components table in README.md (or custom output file)
:: with test results from tests_tmp, updates component tasks in TODO_PLAN.md if present,
:: and optionally exports an aggregated JSON test results matrix on Windows.
::
:: ## Usage
:: tests\update_results.cmd [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [REPO_ROOT] [--output ^<markdown_file^>] [--json [json_file]] [--help]
echo.
echo Aggregates test result marker files (*.success, *.failure) from tests_tmp
echo and updates the Supported Components table in README.md.
echo.
echo Options:
echo   REPO_ROOT              Target repository root path (default: auto-detected).
echo   --output ^<file^>        Custom markdown file to update (default: README.md).
echo   --json [json_file]     Export matrix results as JSON (default: tests_tmp\matrix_results.json).
echo   --help, -h, /?         Show this help message.
exit /b 0

:: ## main
:: Dispatches execution to PowerShell implementation.
:main
set "PS_SCRIPT=%THIS_DIR%\update_results.ps1"
if not exist "%PS_SCRIPT%" (
    if exist "%THIS_DIR%\..\tests\update_results.ps1" (
        set "PS_SCRIPT=%THIS_DIR%\..\tests\update_results.ps1"
    )
)

where powershell >nul 2>&1
if %ERRORLEVEL% equ 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell or pwsh not found. Cannot update results on Windows. >&2
exit /b 1
