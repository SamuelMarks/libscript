@echo off
:: # run_illumos_tests.cmd
::
:: ## Overview
:: Runs tests sequentially on local SunOS/OmniOS Vagrant VM from Windows.
::
:: ## Usage
:: run_illumos_tests.cmd [TARGETS...|all]

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
    echo Usage: %~nx0 [TARGETS...^|all]
    echo Runs tests on SunOS/OmniOS Vagrant VM.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [TARGETS...^|all]
    echo Runs tests on SunOS/OmniOS Vagrant VM.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

echo [TEST]     SunOS / OmniOS Windows runner initialized.
exit /b 0
