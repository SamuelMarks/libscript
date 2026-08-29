@echo off
:: # bootstrap.cmd
::
:: ## Overview
:: Dependency resolution script for bootstrapping the libscript REST API development environment on Windows.
::
:: ## Usage
:: Run via: `.\scripts\bootstrap.cmd`

setlocal enabledelayedexpansion
set "THIS_FILE=%~f0"

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:show_help
:: ## show_help
:: Executes show_help functionality.
echo Usage: %~nx0
echo Dependency resolution script for bootstrapping the libscript REST API development environment on Windows.
echo.
echo Options:
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:main
:: ## main
:: Executes main functionality.
:: Resolve directories
set "SCRIPT_DIR=%~dp0"
:: Remove trailing backslash
set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"
for %%I in ("%SCRIPT_DIR%\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

echo [INFO] Detected Windows. Checking for required build tools...

:: Check for Git
where git >nul 2>&1
if errorlevel 1 (
    echo [INFO] Git not found. Attempting to install via winget...
    winget install --id Git.Git -e --source winget
) else (
    echo [INFO] Git is already installed.
)

:: Check for CMake
where cmake >nul 2>&1
if errorlevel 1 (
    echo [INFO] CMake not found. Attempting to install via winget...
    winget install --id Kitware.CMake -e --source winget
) else (
    echo [INFO] CMake is already installed.
)

:: Check for C Compiler (MSVC / cl.exe)
:: The best way on Windows is Visual Studio Build Tools
where cl >nul 2>&1
if errorlevel 1 (
    echo [INFO] MSVC compiler (cl.exe) not found in PATH.
    echo [INFO] Attempting to install Visual Studio Build Tools via winget...
    winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --override "--wait --quiet --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
    echo [INFO] NOTE: You may need to run this script from a 'x64 Native Tools Command Prompt for VS' after installation.
) else (
    echo [INFO] MSVC compiler is already installed.
)

:: Check for jq
where jq >nul 2>&1
if errorlevel 1 (
    echo [INFO] jq not found. Attempting to install via winget...
    winget install --id jqlang.jq -e --source winget
) else (
    echo [INFO] jq is already installed.
)

echo [INFO] Dependency resolution complete. C compiler, git, and cmake are ready.

:: Fetch c-rest-framework
set "VENDOR_DIR=%SCRIPT_DIR%\..\vendor"
if not exist "%VENDOR_DIR%" mkdir "%VENDOR_DIR%"
if not exist "%VENDOR_DIR%\c-rest-framework\.git" (
    echo [INFO] Cloning c-rest-framework into vendor directory...
    git clone https://github.com/SamuelMarks/c-rest-framework "%VENDOR_DIR%\c-rest-framework"
) else (
    echo [INFO] c-rest-framework already cloned. Pulling latest...
    cd /d "%VENDOR_DIR%\c-rest-framework"
    git fetch --all
    git reset --hard @{upstream}
    cd /d "%SCRIPT_DIR%"
)

echo [INFO] Framework acquisition complete.
