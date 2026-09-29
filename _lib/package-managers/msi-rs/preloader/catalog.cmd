@echo off
set "THIS_FILE=%~f0"
:: # catalog.cmd
::
:: ## Overview
:: Dynamic LibScript Component Catalog Engine for Windows Command Prompt.
:: Queries and filters all components across the ecosystem for live installer menus.
::
:: ## Usage
:: Call catalog.cmd [--json | --search <term> | --clean-base]

setlocal EnableDelayedExpansion

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

goto :main

:: ## show_help
:: Displays usage instructions and supported query options.
:show_help
echo Usage: %~nx0 [--json ^| --search ^<term^> ^| --clean-base]
echo.
echo Queries and formats available LibScript components on Windows.
exit /b 0

:: ## main
:: Executes primary orchestration routine.
:main
set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

where wsl >nul 2>&1
if !errorlevel! EQU 0 (
    wsl sh "%SCRIPT_DIR%catalog.sh" %*
    exit /b !errorlevel!
)

where sh >nul 2>&1
if !errorlevel! EQU 0 (
    sh "%SCRIPT_DIR%catalog.sh" %*
    exit /b !errorlevel!
)

echo [CATALOG] Displaying LibScript components on Windows:
echo nginx                web-servers        High performance HTTP web server
echo wordpress            workloads          WordPress web publishing platform
echo odoo                 app-servers        Odoo Enterprise Business Suite
echo openedx              workloads          Open edX Learning Platform
exit /b 0
