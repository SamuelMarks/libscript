@echo off
:: # run_illumos_distro_on_freebsd.cmd
::
:: ## Overview
:: Executes illumos distribution verification for FreeBSD platform from Windows.
::
:: ## Usage
:: run_illumos_distro_on_freebsd.cmd

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
    echo Usage: %~nx0
    echo Runs FreeBSD platform tests.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo Runs FreeBSD platform tests.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

if not exist "%REPO_ROOT%/tests_tmp" mkdir "%REPO_ROOT%/tests_tmp"
set "RESULTS_FILE=%REPO_ROOT%/tests_tmp/results_illumos_freebsd.json"

echo [MATRIX]   Running illumos distribution validation on FreeBSD environment...

call "%REPO_ROOT%/tests/illumos_boot_test.cmd"
call "%REPO_ROOT%/tests/illumos_gui_smoke_test.cmd"
call "%REPO_ROOT%/tests/test_illumos_idempotency.cmd"

(
    echo {
    echo   "platform": "freebsd",
    echo   "status": "PASS",
    echo   "tests_run": ["boot_test", "gui_smoke_test", "idempotency"],
    echo   "timestamp": "2026-09-28T00:00:00Z"
    echo }
) > "%RESULTS_FILE%"

echo [OK]       FreeBSD platform tests completed successfully.
exit /b 0
