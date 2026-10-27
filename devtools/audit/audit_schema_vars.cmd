@echo off
:: # audit_schema_vars.cmd
::
:: ## Overview
:: Audits all LibScript components in _lib/<category>/<component>/ to ensure that
:: every component-scoped and global configuration variable referenced in scripts
:: is declared and documented in vars.schema.json or base_vars.schema.json.
::
:: ## Usage
:: Execute this script to audit component schema variables:
::   ./devtools/audit/audit_schema_vars.cmd [--all | --staged | <component_dir>...]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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



if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--all ^| --staged]
echo Audits component scripts for undocumented environment variables missing from JSON schemas.
exit /b 0

:: ## main
:: Executes the primary orchestration workflow for this script.
:main
where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot audit schema variables on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%/audit_schema_vars.ps1" %*
exit /b !ERRORLEVEL!
