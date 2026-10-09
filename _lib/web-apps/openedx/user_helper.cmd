@echo off
:: # user_helper.cmd
::
:: ## Overview
:: User management helper utility for Open edX.
:: Manages user account creation, credentials, staff roles, and catalog enumeration.
::
:: ## Usage
:: user_helper.cmd stacks/cms/openedx/user_helper.cmd create <install_dir> <username> <email> <password> <is_staff> <is_superuser>
:: user_helper.cmd stacks/cms/openedx/user_helper.cmd set_password <install_dir> <username> <password>
:: user_helper.cmd stacks/cms/openedx/user_helper.cmd list <install_dir>

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

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

:: # user_helper.cmd
:::: User management helper utility for Open edX on Windows.
:: Manages user account creation, credentials, staff roles, and catalog enumeration.
::
:: ## Usage
:: Call stacks\cms\openedx\user_helper.cmd create <install_dir> <username> <email> <password> <is_staff> <is_superuser>
:: Call stacks\cms\openedx\user_helper.cmd set_password <install_dir> <username> <password>
:: Call stacks\cms\openedx\user_helper.cmd list <install_dir>

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if "%~1"=="" goto :show_help

goto :main

:: ## show_help
:: Displays command line usage documentation.
:show_help
echo Usage: %~nx0 create ^<install_dir^> ^<username^> ^<email^> ^<password^> ^<is_staff^> ^<is_superuser^>
echo        %~nx0 set_password ^<install_dir^> ^<username^> ^<password^>
echo        %~nx0 list ^<install_dir^>
exit /b 0

:: ## main
:: Executes primary entrypoint delegating to user_helper.ps1.
:main
setlocal EnableDelayedExpansion

where powershell >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\user_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

where pwsh >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    pwsh -NoProfile -File "%SCRIPT_DIR%\user_helper.ps1" %*
    exit /b %ERRORLEVEL%
)

echo [ERROR] PowerShell interpreter not found to execute user helper. >&2
exit /b 1
