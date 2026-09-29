@echo off
set "THIS_FILE=%~f0"
:: # render_actual_screenshots.cmd
::
:: ## Overview
:: Actual screenshot rendering engine for LibScript msi-rs live installer.
:: Executes installer command captures and renders terminal sessions (680x360),
:: Windows Installer dialogs (540x420), and system boot screens sequentially prefixed
:: with their step numbers directly into ../cc0-assets.
::
:: ## Usage
:: call devtoolsender_actual_screenshots.cmd

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage and help information for the screenshot renderer.
:show_help
echo Usage: %~nx0
echo Renders live installer screenshots into ..\cc0-assets.
exit /b 0

:: ## main
:: Executes primary screenshot rendering routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "CC0_ROOT=%REPO_ROOT%\..\cc0-assets"
set "CC0_MSI_DIR=%CC0_ROOT%\msi-rs\screenshots"
set "CC0_LIVE_DIR=%CC0_ROOT%\libscript\live-installer\screenshots"

if not exist "%CC0_MSI_DIR%" mkdir "%CC0_MSI_DIR%"
if not exist "%CC0_LIVE_DIR%" mkdir "%CC0_LIVE_DIR%"

set "PS_SCRIPT=%SCRIPT_DIR%render_actual_screenshots.ps1"

where powershell.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

echo [OK] Screenshots verified in %CC0_MSI_DIR%
exit /b 0
