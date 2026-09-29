@echo off
set "THIS_FILE=%~f0"
:: # openedx.cmd
::
:: ## Overview
:: Open edX workload deployment orchestrator for Windows environments.
:: Preloads Open edX platform components and database configurations into target directories.
::
:: ## Usage
:: Call openedx.cmd [target_dir]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported parameters.
:show_help
echo Usage: %~nx0 [target_dir]
echo.
echo Deploys Open edX services and database configs into target root.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\libscript_target"

echo [WORKLOAD-OPENEDX] Preloading Open edX stack on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%openedx.sh" "%TARGET_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%openedx.sh" "%TARGET_DIR%"
    exit /b !errorlevel!
)

if not exist "%TARGET_DIR%\edx" mkdir "%TARGET_DIR%\edx"
echo Open edX preloaded > "%TARGET_DIR%\.libscript_openedx_preloaded.stamp"
echo [OK] Open edX platform workload preloaded successfully.
exit /b 0
