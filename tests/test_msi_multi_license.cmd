@echo off
:: # test_msi_multi_license.cmd
::
:: ## Overview
:: Validates WiX Windows Installer (.msi) multi-license dialog sequence generation on Windows.
:: Asserts that each bundled component receives a dedicated license agreement dialog,
:: individual acceptance checkbox property, sequential UI routing, and unattended guard.
::
:: ## Usage
:: call tests\test_msi_multi_license.cmd

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

where sh.exe >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    sh "%SCRIPT_DIR%\test_msi_multi_license.sh" %*
    exit /b %ERRORLEVEL%
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "& '%SCRIPT_DIR%\test_msi_multi_license.sh'" %*
exit /b %ERRORLEVEL%
