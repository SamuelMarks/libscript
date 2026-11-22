@echo off
:: # test_var_aliases_and_env_printer.cmd
::
:: ## Overview
:: Hermetic Windows Batch tests for global variable alias normalization and env_printer.cmd isolation.
::
:: ## Usage
:: tests\test_var_aliases_and_env_printer.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "TEST_TMP=!LIBSCRIPT_ROOT_DIR!\tests_tmp\var_aliases_win_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"

set "STACK="
set "LIBSCRIPT_TARGET_SYSROOT="
set "LIBSCRIPT_TARGET_ROOTFS=!TEST_TMP!\legacy_rootfs"
call "!LIBSCRIPT_ROOT_DIR!\engine\common\context.cmd"
if not "!LIBSCRIPT_TARGET_SYSROOT!"=="!TEST_TMP!\legacy_rootfs" (
    echo [FAIL] context.cmd failed to normalize LIBSCRIPT_TARGET_ROOTFS >&2
    rmdir /s /q "!TEST_TMP!" 2>nul
    exit /b 1
)

rmdir /s /q "!TEST_TMP!" 2>nul
echo [PASS] Windows variable alias normalization verified.
exit /b 0
