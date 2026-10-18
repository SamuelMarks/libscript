@echo off
:: # health_helper.cmd
::
:: ## Overview
:: Diagnostic healthcheck helper utility for Open edX.
:: Validates connectivity and responsiveness across databases, caches, and web services.
::
:: ## Usage
:: health_helper.cmd stacks/cms/openedx/health_helper.cmd <is_json> <lms_h> <lms_p> <cms_h> <cms_p> <my_h> <my_p> <mg_h> <mg_p> <rd_h> <rd_p> <me_h> <me_p> <sm_h> <sm_p>

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
echo Usage: %~nx0 ^<is_json^> ^<lms_h^> ^<lms_p^> ^<cms_h^> ^<cms_p^> ^<my_h^> ^<my_p^> ^<mg_h^> ^<mg_p^> ^<rd_h^> ^<rd_p^> ^<me_h^> ^<me_p^> ^<sm_h^> ^<sm_p^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to health_helper.ps1.
:main

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\health_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "!SCRIPT_DIR!\health_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute healthcheck helper. >&2
exit /b 1
