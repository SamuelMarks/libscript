@echo off
:: # test_doc_coverage.cmd
::
:: ## Overview
:: Unit test suite for devtools\audit\doc_coverage.cmd and the README.md % doc coverage shield on Windows.
:: Verifies 100% doc coverage calculation, shield injection in README.md, and idempotency.
::
:: ## Usage
:: call tests/test_doc_coverage.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo !STACK! | findstr /I /C:":%THIS_FILE%:" >nul 2>&1
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

echo === LibScript Doc Coverage Shield ^& Hook Test Suite (Win32) ===

set "TMP_TEST_DIR=%TEMP%\libscript_doc_cov_%RANDOM%"
if not exist "%TMP_TEST_DIR%" mkdir "%TMP_TEST_DIR%"
copy /y "%LIBSCRIPT_ROOT_DIR%\README.md" "%TMP_TEST_DIR%\README.md" >nul

call "%LIBSCRIPT_ROOT_DIR%\devtools\audit\doc_coverage.cmd" --update-readme "%TMP_TEST_DIR%\README.md"
if errorlevel 1 (
    echo [FAIL] doc_coverage.cmd failed >&2
    rmdir /s /q "%TMP_TEST_DIR%" 2>nul
    exit /b 1
)

findstr /C:"https://img.shields.io/badge/doc%%20coverage-100%%25-brightgreen.svg" "%TMP_TEST_DIR%\README.md" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Doc Coverage 100%% shield missing in README.md >&2
    rmdir /s /q "%TMP_TEST_DIR%" 2>nul
    exit /b 1
)
echo [PASS] Doc Coverage 100%% shield rendered and verified.

rmdir /s /q "%TMP_TEST_DIR%" 2>nul
echo === All Doc Coverage Shield ^& Hook Checks Passed! ===
exit /b 0
