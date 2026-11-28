@echo off
:: # test.cmd
:: ## Overview
:: Smoke and idempotency test suite for the `libtpu-rs` component on Windows.
::
:: ## Usage
:: _lib\toolchains\libtpu-rs\test.cmd

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

set "_TEST_TMP=%TEMP%\libtpu_rs_test_%RANDOM%"
if not exist "!_TEST_TMP!" mkdir "!_TEST_TMP!"
> "!_TEST_TMP!\mock_tpu.dll" echo mock-rs-libtpu-dll
> "!_TEST_TMP!\mock_sdk.dll" echo mock-rs-sdk-dll
> "!_TEST_TMP!\libtpu-0.0.52-cp312-abi3-win_amd64.whl" echo mock-rs-wheel

set "LIBSCRIPT_HOME=!_TEST_TMP!\home"
set "LIBSCRIPT_OFFLINE=1"
set "LIBTPU_RS_SO_PATH=!_TEST_TMP!\mock_tpu.dll"
set "LIBTPU_RS_SDK_SO_PATH=!_TEST_TMP!\mock_sdk.dll"
set "LIBTPU_RS_WHEEL_PATH=!_TEST_TMP!\libtpu-0.0.52-cp312-abi3-win_amd64.whl"
set "STACK="
set "ACTION=install"
call "!SCRIPT_DIR!\setup_generic.cmd" >nul
if errorlevel 1 exit /b 1
set "STACK="
call "!SCRIPT_DIR!\setup_generic.cmd" >nul
if errorlevel 1 exit /b 1

set "LIBTPU_RS_SO_PATH="
set "LIBTPU_RS_SDK_SO_PATH="
set "LIBTPU_RS_WHEEL_PATH="
set "LIBTPU_RS_SO_SHA256="
set "STACK="
call "!SCRIPT_DIR!\env.cmd"
if errorlevel 1 exit /b 1
if "!LIBTPU_RS_SO_SHA256!"=="" exit /b 1
call libtpu-rs-env --version >nul
if errorlevel 1 exit /b 1
rmdir /s /q "!_TEST_TMP!" >nul 2>&1
exit /b 0
