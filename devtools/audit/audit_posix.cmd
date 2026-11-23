@echo off
:: # audit_posix.cmd
:: ## Overview
:: Windows Batch companion for POSIX compliance and companion pairing audit. Audits all tracked .sh and .cmd scripts for POSIX /bin/sh invariants, absence of bashisms, canonical THIS_FILE= resolution dance, and Windows batch companion parity.
:: ## Usage
:: devtools\audit\audit_posix.cmd [--all | file1.sh ...]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help
if /I "%~1"=="/?" goto :show_help
if /I "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions for audit_posix.cmd.
:show_help
echo Usage: %~nx0 [--all ^| --staged ^| ^<file^>...]
echo Audits shell scripts for strict POSIX /bin/sh compliance and Windows Batch companion parity.
exit /b 0

:: ## main
:: Dispatches execution to the PowerShell POSIX and companion parity auditor.
:main
where pwsh.exe >nul 2>&1
if "%ERRORLEVEL%" EQU "0" (
    pwsh.exe -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%\audit_posix.ps1" %*
    exit /b !ERRORLEVEL!
)

where powershell.exe >nul 2>&1
if "%ERRORLEVEL%" EQU "0" (
    powershell.exe -NoProfile -ExecutionPolicy Bypass -File "!SCRIPT_DIR!\audit_posix.ps1" %*
    exit /b !ERRORLEVEL!
)

if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\dash\env.cmd" (
    call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\dash\env.cmd" >nul 2>&1
)
where dash >nul 2>&1
if "%ERRORLEVEL%" EQU "0" (
    set "LIBSCRIPT_ROOT_DIR=!LIBSCRIPT_ROOT_DIR:\=/!"
    set "_AP_SH=!SCRIPT_DIR:\=/!/audit_posix.sh"
    set "STACK="
    dash "!_AP_SH!" %*
    exit /b !ERRORLEVEL!
)

call :native_batch_posix_audit
exit /b !ERRORLEVEL!

:: ## native_batch_posix_audit
:: Audits .sh/.cmd companion pairing and canonical headers using native Windows Batch and findstr.
:native_batch_posix_audit
set "_AP_ERRS=0"
for /f "delims=" %%F in ('git -C "!LIBSCRIPT_ROOT_DIR!" ls-files "*.sh" 2^>nul') do (
    set "_SH_REL=%%F"
    set "_CMD_REL=!_SH_REL:~0,-3!.cmd"
    set "_BAT_REL=!_SH_REL:~0,-3!.bat"
    if not exist "!LIBSCRIPT_ROOT_DIR!\!_CMD_REL!" if not exist "!LIBSCRIPT_ROOT_DIR!\!_BAT_REL!" (
        echo [FAIL] [%%F] Missing paired Windows batch companion: !_CMD_REL! 1>&2
        set /a "_AP_ERRS+=1"
    )
    findstr /B /C:"#!/bin/sh" "!LIBSCRIPT_ROOT_DIR!\%%F" >nul 2>&1
    if errorlevel 1 (
        echo [FAIL] [%%F] Missing strict #^^!/bin/sh shebang 1>&2
        set /a "_AP_ERRS+=1"
    )
)
REM wincheck disable=CMD2003
if !_AP_ERRS! gtr 0 (
    echo [ERROR] Native Batch POSIX audit failed with !_AP_ERRS! violation^(s^)^^! 1>&2
    exit /b 1
)
echo [PASS] Native Batch POSIX and companion audit passed.
exit /b 0
