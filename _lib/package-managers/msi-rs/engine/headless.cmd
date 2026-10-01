@echo off
set "THIS_FILE=%~f0"
:: # headless.cmd
::
:: ## Overview
:: Headless non-interactive installer orchestrator for Windows environments.
:: Implements msiexec property injection and unattended execution workflows.
::
:: ## Usage
:: Call headless.cmd [/i <package.msi>] [/qn|/passive] [KEY=VALUE...]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [/i ^<package.msi^>] [/qn^|/passive] [KEY=VALUE...]
echo.
echo Executes headless automated installation using msiexec syntax on Windows.
echo.
echo Options:
echo   /i ^<package.msi^>     Target MSI installer package
echo   /qn                  Completely silent execution (no UI)
echo   /passive             Unattended progress-only execution
echo   TARGET_DISK=^<num^>    Target disk number
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [HEADLESS] Starting headless automated installer on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%headless.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%headless.sh" %*
    exit /b !errorlevel!
)

echo [ERROR] No POSIX shell (wsl or sh) found on this Windows system.
echo [ERROR] Headless installation via msi-rs requires a shell or native diskpart integration.
exit /b 1
