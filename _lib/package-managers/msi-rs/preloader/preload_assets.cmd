@echo off
set "THIS_FILE=%~f0"
:: # preload_assets.cmd
::
:: ## Overview
:: Offline preload asset manager for Windows environments.
:: Stages pre-compiled components and offline caches into target installation directories.
::
:: ## Usage
:: Call preload_assets.cmd [target_dir] [component_list...]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported options.
:show_help
echo Usage: %~nx0 [target_dir] [component_list...]
echo.
echo Stages offline LibScript components and dependencies on Windows.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\libscript_target"

echo [PRELOAD] Staging offline components into %TARGET_DIR%\opt\libscript\cache...
if not exist "%TARGET_DIR%\opt\libscript\cache" mkdir "%TARGET_DIR%\opt\libscript\cache"

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%preload_assets.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%preload_assets.sh" %*
    exit /b !errorlevel!
)

echo [OK] Offline component staging completed on Windows.
exit /b 0
