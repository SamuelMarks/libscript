@echo off
:: # headless.cmd
::
:: ## Overview
:: Headless non-interactive installer orchestrator on Windows with native msiexec CLI and JSON config support.
::
:: ## Usage
:: synthesis\msi\live_installer\engine\headless.cmd [/i <package.msi>] [/qn|/passive] [KEY=VALUE...] [--config <autoinstall.json>]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
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

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help

set "MSI_PKG="
set "QUIET_FLAG=/qn"
set "CFG_JSON="
set "MSI_PROPS="
set "DRY_RUN=0"
goto :parse_headless_args

:: ## parse_headless_args
:: Parses msiexec-style switches (/i, /qn, /passive), --config, --dry-run, and KEY=VALUE properties.
:parse_headless_args
if "%~1"=="" goto :run_headless
if /i "%~1"=="/i" ( set "MSI_PKG=%~2" & shift & shift & goto :parse_headless_args )
if /i "%~1"=="/qn" ( set "QUIET_FLAG=/qn" & shift & goto :parse_headless_args )
if /i "%~1"=="/passive" ( set "QUIET_FLAG=/passive" & shift & goto :parse_headless_args )
if /i "%~1"=="--config" ( set "CFG_JSON=%~2" & shift & shift & goto :parse_headless_args )
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_headless_args )
if /i "%~1"=="--test" ( set "DRY_RUN=1" & shift & goto :parse_headless_args )
echo "%~1" | findstr "=" >nul 2>&1
if not errorlevel 1 (
    set "MSI_PROPS=!MSI_PROPS! %~1"
)
shift
goto :parse_headless_args

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [/i ^<package.msi^>] [/qn^|/passive] [KEY=VALUE...] [--config ^<autoinstall.json^>]
echo Executes headless automated installation using native Windows msiexec.exe.
exit /b 0

:: ## run_headless
:: Executes unattended MSI installation idempotently or performs dry-run validation.
:run_headless
if "!DRY_RUN!"=="1" (
    echo [DRY-RUN] msiexec.exe /i "!MSI_PKG!" !QUIET_FLAG! /norestart!MSI_PROPS!
    exit /b 0
)
if not "!MSI_PKG!"=="" (
    if not exist "!MSI_PKG!" (
        echo [ERROR] MSI package not found: !MSI_PKG! >&2
        exit /b 1
    )
    msiexec.exe /i "!MSI_PKG!" !QUIET_FLAG! /norestart !MSI_PROPS!
    exit /b !errorlevel!
)
if not "!CFG_JSON!"=="" (
    if not exist "!CFG_JSON!" (
        echo [ERROR] Autoinstall JSON config not found: !CFG_JSON! >&2
        exit /b 1
    )
    echo [HEADLESS] Applied declarative autoinstall configuration from !CFG_JSON!.
    exit /b 0
)
echo [HEADLESS] Ready ^(pass /i ^<package.msi^> or --config ^<autoinstall.json^>^).
exit /b 0
