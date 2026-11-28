@echo off
:: # test.cmd
:: ## Overview
:: Smoke and idempotency test suite for the upstream reference `libtpu` component on Windows.
::
:: ## Usage
:: _lib\runtimes\libtpu\test.cmd

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

set "_TEST_TMP=%TEMP%\libtpu_test_%RANDOM%"
if not exist "!_TEST_TMP!" mkdir "!_TEST_TMP!"
> "!_TEST_TMP!\mock_libtpu.so" echo mock-og-libtpu-elf
> "!_TEST_TMP!\mock_sdk.so" echo mock-og-sdk-elf
> "!_TEST_TMP!\libtpu-0.0.52.whl" echo mock-og-wheel

set "LIBSCRIPT_HOME=!_TEST_TMP!\home"
set "LIBTPU_SO_PATH=!_TEST_TMP!\mock_libtpu.so"
set "LIBTPU_SDK_SO_PATH=!_TEST_TMP!\mock_sdk.so"
set "LIBTPU_REFERENCE_WHEEL=!_TEST_TMP!\libtpu-0.0.52.whl"
set "STACK="
set "ACTION=install"
call "!SCRIPT_DIR!\setup_generic.cmd" >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\setup_generic.cmd" >nul
if errorlevel 1 exit /b 1

set "LIBTPU_SO_PATH="
set "LIBTPU_SDK_SO_PATH="
set "LIBTPU_REFERENCE_WHEEL="
set "LIBTPU_REFERENCE_SO_SHA256="
set "STACK="
call "!SCRIPT_DIR!\env.cmd"
if errorlevel 1 exit /b 1
if "!LIBTPU_REFERENCE_SO_SHA256!"=="" exit /b 1
call libtpu-info --version >nul
if errorlevel 1 exit /b 1
rmdir /s /q "!_TEST_TMP!" >nul 2>&1
exit /b 0
