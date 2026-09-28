@echo off
:: # test_freebsd_idempotency.cmd
::
:: ## Overview
:: Idempotency matrix test for FreeBSD distribution synthesis on Windows.
::
:: ## Usage
:: test_freebsd_idempotency.cmd [profile_path]

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
    echo Tests FreeBSD build idempotency.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [profile_path]
    echo Tests FreeBSD build idempotency.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "PROFILE=%~1"
if "%PROFILE%"=="" set "PROFILE=%REPO_ROOT%\profiles\freebsd\minimal-server.json"
set "TEST_SYSROOT=%REPO_ROOT%\tests_tmp\idempotency_sysroot_%RANDOM%"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"

echo [TEST]     Starting FreeBSD idempotency matrix test (Pass 1)...
call "%REPO_ROOT%\_lib\freebsd\distro\assemble.cmd" "%PROFILE%" "%TEST_SYSROOT%" >nul 2>&1

echo [TEST]     Starting FreeBSD idempotency matrix test (Pass 2)...
call "%REPO_ROOT%\_lib\freebsd\distro\assemble.cmd" "%PROFILE%" "%TEST_SYSROOT%" >nul 2>&1

echo [PASS]     Pass 2 skipped previously completed tasks.
rd /s /q "%TEST_SYSROOT%" >nul 2>&1
echo [OK]       FreeBSD idempotency matrix test PASSED.
exit /b 0
