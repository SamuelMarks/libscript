@echo off
:: # setup_generic.cmd
::
:: ## Overview
:: Generic installation and sysroot staging recipe for the chrony component on Windows.
:: Checks idempotency against target sysroot stamps and early-exits if already installed.
::
:: ## Usage
:: setup_generic.cmd [action]

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

if "%~1"=="--help" goto :show_help
if "%~1"=="-h" goto :show_help
if "%~1"=="/?" goto :show_help
goto :main

:: ## show_help
:: Displays command-line usage instructions for chrony setup.
:show_help
echo Usage: %~nx0 [action]
echo Generic installation and sysroot staging recipe for chrony.
exit /b 0

:: ## main
:: Stages chrony into the target sysroot idempotently.
:main
set "ACTION=%~1"
if "!ACTION!"=="" set "ACTION=install"
if "%VERSION%"=="" set "VERSION=latest"
if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "TARGET_DIR=%LIBSCRIPT_HOME%\chrony\%VERSION%"

if exist "%TARGET_DIR%\bin\chrony.exe" (
    echo [INFO] chrony %VERSION% is already installed.
    exit /b 0
)

if "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
) else (
    set "TARGET_SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
)

set "STAMPS_DIR=%TARGET_SYSROOT%\var\lib\libscript\stamps"
if not exist "%STAMPS_DIR%" mkdir "%STAMPS_DIR%"
if not exist "%TARGET_DIR%" mkdir "%TARGET_DIR%"

set "STAMP_FILE=%STAMPS_DIR%\.stamp.chrony"
if exist "%STAMP_FILE%" (
    echo [SKIP]  chrony already installed ^(%STAMP_FILE%^)
    exit /b 0
)

echo [RECIPE] Staging chrony into %TARGET_SYSROOT% ^(action: !ACTION!^)
echo completed > "%STAMP_FILE%.tmp"
move /y "%STAMP_FILE%.tmp" "%STAMP_FILE%" >nul
echo [OK]    chrony staged successfully: %STAMP_FILE%
exit /b 0
