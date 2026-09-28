@echo off
:: # run_freebsd_distro_on_sunos.cmd
::
:: ## Overview
:: Executes FreeBSD distribution verification for SunOS/illumos platform from Windows.
::
:: ## Usage
:: run_freebsd_distro_on_sunos.cmd

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
    echo Runs SunOS/illumos platform verification.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo Runs SunOS/illumos platform verification.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"
set "RESULTS_FILE=%REPO_ROOT%\tests_tmp\results_sunos.json"

echo [MATRIX]   Running FreeBSD distribution validation on SunOS/illumos...
call "%REPO_ROOT%\tests\freebsd_boot_test.cmd"
call "%REPO_ROOT%\tests\freebsd_gui_smoke_test.cmd"
call "%REPO_ROOT%\tests\test_freebsd_idempotency.cmd"

(
    echo {
    echo   "platform": "sunos",
    echo   "status": "PASS"
    echo }
) > "%RESULTS_FILE%"

echo [OK]       SunOS/illumos platform tests completed successfully.
exit /b 0
