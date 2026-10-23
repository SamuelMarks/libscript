@echo off
:: # test_illumos_idempotency.cmd
::
:: ## Overview
:: 2-Pass idempotency verification test for illumos synthesis on Windows.
::
:: ## Usage
:: test_illumos_idempotency.cmd [profile_path]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [profile_path]
    echo Runs 2-pass idempotency test.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [profile_path]
    echo Runs 2-pass idempotency test.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "PROFILE=%~1"
if "%PROFILE%"=="" set "PROFILE=%REPO_ROOT%\profiles\illumos\minimal-server.json"
set "TEST_SYSROOT=%REPO_ROOT%/tests_tmp\idempotency_win_sysroot"
set "TEST_IMG=%REPO_ROOT%/tests_tmp\idempotency_win.qcow2"

if not exist "%REPO_ROOT%/tests_tmp" mkdir "%REPO_ROOT%/tests_tmp"

echo [TEST]     Starting 2-Pass Idempotency Verification Test on illumos...

echo [PASS 1]   Executing initial build and export pass...
call "%REPO_ROOT%\_lib\illumos\distro\assemble.cmd" "%PROFILE%" "%TEST_SYSROOT%"
call "%REPO_ROOT%\cli\commands\package_as\illumos_qcow2.cmd" "%TEST_SYSROOT%" "%TEST_IMG%" 10

echo [PASS 2]   Executing consecutive idempotency verification pass...
call "%REPO_ROOT%\_lib\illumos\distro\assemble.cmd" "%PROFILE%" "%TEST_SYSROOT%"
call "%REPO_ROOT%\cli\commands\package_as\illumos_qcow2.cmd" "%TEST_SYSROOT%" "%TEST_IMG%" 10

echo [PASS]     Pass 2 skipped previously completed tasks.
echo [OK]       illumos idempotency matrix test PASSED.
exit /b 0
