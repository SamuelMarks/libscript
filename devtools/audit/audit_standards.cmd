@echo off
:: # audit_standards.cmd
::
:: ## Overview
:: Audits codebase and staged files for adherence to LibScript engineering standards:
:: - POSIX /bin/sh usage and canonical THIS_FILE preamble
:: - Windows batch script parity (.cmd / .bat)
:: - No evil eval usage
:: - Idempotency patterns
:: - 100% doc block coverage (:::: Overview and :::: Usage)
::
:: ## Usage
:: Execute this script to audit files:
::   ./devtools/audit/audit_standards.cmd [--all | --staged | <file>...]

setlocal EnableDelayedExpansion
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



if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--all ^| --staged]
echo Audits files for adherence to LibScript engineering standards.
echo.
echo Options:
echo   --all               Audit all tracked script files in repository.
echo   --staged            Audit git-staged files (default if no files given).
echo   --help, -h, /?, -?  Show this help message.
exit /b 0

:: ## main
:: Executes the primary orchestration workflow for this script.
:main
set "ROOT_DIR=%~dp0..\.."

where powershell >nul 2>&1
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] PowerShell not found. Cannot audit standards on Windows.
    exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\audit_standards.ps1" %*
exit /b !ERRORLEVEL!
