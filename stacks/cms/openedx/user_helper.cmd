@echo off
set "THIS_FILE=%~f0"
:: # user_helper.cmd
::
:: ## Overview
:: User management helper utility for Open edX on Windows.
:: Manages user account creation, credentials, staff roles, and catalog enumeration.
::
:: ## Usage
:: Call stacks\cms\openedx\user_helper.cmd create <install_dir> <username> <email> <password> <is_staff> <is_superuser>
:: Call stacks\cms\openedx\user_helper.cmd set_password <install_dir> <username> <password>
:: Call stacks\cms\openedx\user_helper.cmd list <install_dir>

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 create ^<install_dir^> ^<username^> ^<email^> ^<password^> ^<is_staff^> ^<is_superuser^>
echo        %~nx0 set_password ^<install_dir^> ^<username^> ^<password^>
echo        %~nx0 list ^<install_dir^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to user_helper.ps1.
:main
setlocal EnableDelayedExpansion
set "SCRIPT_DIR=%~dp0"

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%user_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%user_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute user helper. >&2
exit /b 1
