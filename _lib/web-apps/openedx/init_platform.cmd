@echo off
:: # init_platform.cmd
::
:: ## Overview
:: Platform database and service initialization engine for Open edX on Windows.
:: Delegates to init_platform.ps1 to run LMS/CMS migrations, Casbin policies,
:: Studio OAuth2 SSO DOT applications, SiteConfigurations, 12 Studio MFE waffle switches,
:: and System Taxonomies.
::
:: ## Usage
:: call init_platform.cmd [-InstallDir <path>]

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

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\init_platform.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "!SCRIPT_DIR!\init_platform.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute init_platform.ps1. >&2
exit /b 1
