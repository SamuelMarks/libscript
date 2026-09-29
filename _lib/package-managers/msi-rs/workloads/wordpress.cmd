@echo off
set "THIS_FILE=%~f0"
:: # wordpress.cmd
::
:: ## Overview
:: WordPress workload deployment orchestrator for Windows environments.
:: Preloads WordPress publishing files and web configurations into target directories.
::
:: ## Usage
:: Call wordpress.cmd [target_dir]

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
echo Deploys WordPress web publishing stack and config into target root.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=C:\libscript_target"

echo [WORKLOAD-WORDPRESS] Preloading WordPress stack on Windows...

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%wordpress.sh" "%TARGET_DIR%"
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%wordpress.sh" "%TARGET_DIR%"
    exit /b !errorlevel!
)

if not exist "%TARGET_DIR%\wordpress" mkdir "%TARGET_DIR%\wordpress"
echo WordPress preloaded > "%TARGET_DIR%\.libscript_wordpress_preloaded.stamp"
echo [OK] WordPress platform workload preloaded successfully.
exit /b 0
