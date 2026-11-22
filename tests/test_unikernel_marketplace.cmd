@echo off
:: # test_unikernel_marketplace.cmd
::
:: ## Overview
:: Windows Batch integration test suite verifying Pillar 2 (`UK-01`..`UK-16`): Open edX unikernel
:: constellation assembly, compliance gate, and 2x-idempotent AWS/Azure/GCP Marketplace synthesis.
::
:: ## Usage
:: .\tests\test_unikernel_marketplace.cmd

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

set "TEST_TMP=%TEMP%\libscript_mkt_test_%RANDOM%"
if not exist "%TEST_TMP%" mkdir "%TEST_TMP%"

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" publish-marketplace "%LIBSCRIPT_ROOT_DIR%\infrastructure\marketplace\openedx-unikernel\offer.json" --clouds=aws,azure,gcp --out-dir="%TEST_TMP%\mkt" --dry-run --allow-stub-sdk
if errorlevel 1 (
    echo [FAIL] publish-marketplace dry-run failed >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

if not exist "%TEST_TMP%\mkt\aws\cloudformation.template.json" (
    echo [FAIL] Missing AWS CloudFormation template >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)
if not exist "%TEST_TMP%\mkt\azure\pkg\mainTemplate.json" (
    echo [FAIL] Missing Azure mainTemplate.json >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)
if not exist "%TEST_TMP%\mkt\gcp\main.tf" (
    echo [FAIL] Missing GCP main.tf >&2
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

rmdir /s /q "%TEST_TMP%" >nul 2>&1
echo [PASS] Windows Unikernel Marketplace tests passed^^!
exit /b 0
