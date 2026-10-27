@echo off
:: # workers_helper.cmd
::
:: ## Overview
:: Background worker process manager helper for Open edX.
:: Manages daemon lifecycle, status monitoring, and graceful termination of workers.
::
:: ## Usage
:: workers_helper.cmd _lib/web-apps/openedx/workers_helper.cmd start <run_dir> <log_dir> <py_bin> <install_dir>
:: workers_helper.cmd _lib/web-apps/openedx/workers_helper.cmd stop <run_dir>
:: workers_helper.cmd _lib/web-apps/openedx/workers_helper.cmd status <run_dir>

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
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 start ^<run_dir^> ^<log_dir^> ^<py_bin^> ^<install_dir^>
echo        %~nx0 stop ^<run_dir^>
echo        %~nx0 status ^<run_dir^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to workers_helper.ps1.
:main

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\workers_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "!SCRIPT_DIR!\workers_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute workers helper. >&2
exit /b 1
