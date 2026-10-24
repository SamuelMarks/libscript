@echo off
:: # test_multi_env_inheritance.cmd
::
:: ## Overview
:: Integration test verifying that a multi-component backend manifest
:: (nodejs + postgres + python) properly propagates and inherits PATH
:: across env.cmd, env_printer.cmd, and run_hooks.cmd on Windows.
::
:: ## Usage
:: tests\test_multi_env_inheritance.cmd

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

set "TEST_TMP=%TEMP%\libscript_multi_env_test_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"
set "LIBSCRIPT_HOME=!TEST_TMP!\home"
if not exist "!LIBSCRIPT_HOME!\nodejs\22\bin" mkdir "!LIBSCRIPT_HOME!\nodejs\22\bin"
if not exist "!LIBSCRIPT_HOME!\postgres\17\bin" mkdir "!LIBSCRIPT_HOME!\postgres\17\bin"
if not exist "!LIBSCRIPT_HOME!\python\3.12\bin" mkdir "!LIBSCRIPT_HOME!\python\3.12\bin"

set "NODEJS_VERSION=22"
set "POSTGRES_VERSION=17"
set "PYTHON_VERSION=3.12"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\nodejs\env.cmd"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\databases\postgres\env.cmd"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\languages\python\env.cmd"

echo "!PATH!" | findstr /I /C:"nodejs\22\bin" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] nodejs\22\bin missing from PATH
    rmdir /s /q "!TEST_TMP!" 2>nul
    exit /b 1
)
echo "!PATH!" | findstr /I /C:"postgres\17\bin" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] postgres\17\bin missing from PATH
    rmdir /s /q "!TEST_TMP!" 2>nul
    exit /b 1
)
echo "!PATH!" | findstr /I /C:"python\3.12\bin" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] python\3.12\bin missing from PATH
    rmdir /s /q "!TEST_TMP!" 2>nul
    exit /b 1
)

rmdir /s /q "!TEST_TMP!" 2>nul
echo [PASS] Multi-component PATH inheritance verified on Windows!
exit /b 0
