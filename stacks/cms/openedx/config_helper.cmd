@echo off
set "THIS_FILE=%~f0"
:: # config_helper.cmd
::
:: ## Overview
:: Configuration helper utility for Open edX configuration management on Windows.
:: Provides key inspection, mutation, default generation, and syntax validation.
::
:: ## Usage
:: Call stacks\cms\openedx\config_helper.cmd get <conf_file> <key>
:: Call stacks\cms\openedx\config_helper.cmd set <conf_file1> <conf_file2> <key> <val>
:: Call stacks\cms\openedx\config_helper.cmd generate <conf_file1> <conf_file2>
:: Call stacks\cms\openedx\config_helper.cmd validate <conf_file> <schema_file>

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 get ^<conf_file^> ^<key^>
echo        %~nx0 set ^<conf_file1^> ^<conf_file2^> ^<key^> ^<val^>
echo        %~nx0 generate ^<conf_file1^> ^<conf_file2^>
echo        %~nx0 validate ^<conf_file^> ^<schema_file^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to config_helper.ps1.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%config_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%config_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute config helper. >&2
exit /b 1
