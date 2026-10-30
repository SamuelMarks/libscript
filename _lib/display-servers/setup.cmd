@echo off
:: # setup.cmd
:: ## Overview
:: Windows Batch companion for Master LFS Display Server dispatcher.
:: Implements Option A Win32 Hard-Fail boundary proforma.
::
:: ## Usage
:: _lib\display-servers\setup.cmd [server] [action] [target_rootfs]

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



IF "%~1"=="status" (
    echo === Display Server Status (Win32) ===
    echo Display server configuration executes inside Linux container or VM builder.
    goto end
)

:: Option A Win32 Hard-Fail Boundary Proforma
echo [ERROR] Native Linux display server configuration is unavailable on Win32. >&2
echo [ERROR] Please execute via container or VM builder: vm_builder.cmd >&2
exit /b 86

:: ## end
:: Performs the end operation and updates component state.
:end
exit /b 0
