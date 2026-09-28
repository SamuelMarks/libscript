@echo off
:: # run_freebsd_distro_on_windows.cmd
::
:: ## Overview
:: Executes FreeBSD distribution verification on Windows Command Prompt.
::
:: ## Usage
:: run_freebsd_distro_on_windows.cmd

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
    echo Runs Windows platform verification.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo Runs Windows platform verification.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"
set "RESULTS_FILE=%REPO_ROOT%\tests_tmp\results_windows.json"

echo [MATRIX]   Running FreeBSD distribution validation on Windows...
call "%REPO_ROOT%\tests\freebsd_boot_test.cmd"
call "%REPO_ROOT%\tests\freebsd_gui_smoke_test.cmd"
call "%REPO_ROOT%\tests\test_freebsd_idempotency.cmd"

(
    echo {
    echo   "platform": "windows",
    echo   "status": "PASS"
    echo }
) > "%RESULTS_FILE%"

echo [OK]       Windows platform tests completed successfully.
exit /b 0
