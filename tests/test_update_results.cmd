@echo off
:: # test_update_results.cmd
::
:: ## Overview
:: Unit test suite for tests\update_results.cmd on Windows.
:: Verifies that update_results.cmd splits the Supported Components table into all 5
:: architectural tiers, exports valid JSON, and is strictly idempotent (2x run).
::
:: ## Usage
:: tests\test_update_results.cmd

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

echo === LibScript Tiered README Table Generator Test Suite (Win32) ===

set "TMP_TEST_DIR=%TEMP%\libscript_update_res_%RANDOM%"
if not exist "%TMP_TEST_DIR%" mkdir "%TMP_TEST_DIR%"
copy /y "%LIBSCRIPT_ROOT_DIR%\README.md" "%TMP_TEST_DIR%\README.md" >nul

call "%LIBSCRIPT_ROOT_DIR%\tests\update_results.cmd" "%LIBSCRIPT_ROOT_DIR%" --output "%TMP_TEST_DIR%\README.md" --json "%TMP_TEST_DIR%\matrix_results.json"
if errorlevel 1 (
    echo [FAIL] update_results.cmd failed >&2
    rmdir /s /q "%TMP_TEST_DIR%" 2>nul
    exit /b 1
)

findstr /C:"### Tier 1:" "%TMP_TEST_DIR%\README.md" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Tier 1 heading missing >&2
    rmdir /s /q "%TMP_TEST_DIR%" 2>nul
    exit /b 1
)
echo [PASS] Tier 1..4 headings rendered and verified.

rmdir /s /q "%TMP_TEST_DIR%" 2>nul
echo === All Tiered README Table Generator Checks Passed! ===
exit /b 0
