@echo off
:: # update_results.cmd
::
:: ## Overview
:: Updates the Supported Components table in README.md (or custom output file)
:: with test results from tests_tmp/, updates task completion in TODO_PLAN.md if present,
:: and optionally exports an aggregated JSON test results matrix.
::
:: ## Usage
:: update_results.cmd tests/update_results.cmd [REPO_ROOT] [--output <markdown_file>] [--json [json_file]] [--help]

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


set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [REPO_ROOT] [--output ^<markdown_file^>] [--json [json_file]] [--help]
echo.
echo Aggregates test result marker files (*.success, *.failure) from tests_tmp
echo and updates the Supported Components table in README.md.
echo.
echo Options:
echo   REPO_ROOT              Target repository root path (default: auto-detected).
echo   --output ^<file^>        Custom markdown file to update (default: README.md).
echo   --json [json_file]     Export matrix results as JSON (default: tests_tmp\matrix_results.json).
echo   --help, -h, /?         Show this help message.
exit /b 0

:: ## main
:: Dispatches execution to PowerShell implementation.
:main
set "PS_SCRIPT=%THIS_DIR%\update_results.ps1"
if not exist "%PS_SCRIPT%" (
    if exist "%THIS_DIR%\..\tests\update_results.ps1" (
        set "PS_SCRIPT=%THIS_DIR%\..\tests\update_results.ps1"
    )
)

where powershell >nul 2>&1
if %ERRORLEVEL% equ 0 (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% equ 0 (
    pwsh -NoProfile -ExecutionPolicy Bypass -File "%PS_SCRIPT%" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell or pwsh not found. Cannot update results on Windows. >&2
exit /b 1
