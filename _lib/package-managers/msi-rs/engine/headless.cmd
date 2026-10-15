@echo off
:: # headless.cmd
::
:: ## Overview
:: Headless non-interactive installer orchestrator with full msiexec CLI parity.
:: Executes unattended, preseeded OS installations driven by MSI properties,
:: JSON response files, and silent (/qn) execution flags across Linux, FreeBSD, and illumos.
::
:: ## Usage
:: Execute this script to run headless installation:
::   ./_lib/package-managers/msi-rs/engine/headless.cmd [/i <package.msi>] [/qn|/passive] [KEY=VALUE...] [--config <autoinstall.json>]

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=%SCRIPT_DIR%"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found

:: # headless.cmd
:::: Headless non-interactive installer orchestrator for Windows environments.
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
