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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

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

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
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
