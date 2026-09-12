@echo off
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
:: # test_run_native_tests.cmd
::
:: ## Overview
:: Validates run_native_tests.cmd execution, verifying CLI options,
:: dry-run mode, and output artifact creation on Windows.
::
:: ## Usage
:: tests\test_run_native_tests.cmd

set "THIS_DIR=%~dp0"
if "%THIS_DIR:~-1%"=="" set "THIS_DIR=%THIS_DIR:~0,-1%"
set "REPO_ROOT=%THIS_DIR%\.."
for %%I in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fI"

set "TEST_TMP=%TEMP%\test_run_native_%RANDOM%"
mkdir "%TEST_TMP%" >nul 2>&1
mkdir "%TEST_TMP%\_lib\catA\compA" >nul 2>&1
mkdir "%TEST_TMP%\_lib\catB\compB" >nul 2>&1
mkdir "%TEST_TMP%\_lib\_common" >nul 2>&1
mkdir "%TEST_TMP%\tests" >nul 2>&1

type nul > "%TEST_TMP%\libscript.cmd"

> "%TEST_TMP%\_lib\catA\compA\manifest.json" (
    echo {
    echo   "name": "compA",
    echo   "os_whitelist": ["all"],
    echo   "os_blacklist": []
    echo }
)

> "%TEST_TMP%\_lib\catB\compB\manifest.json" (
    echo {
    echo   "name": "compB",
    echo   "os_whitelist": ["all"],
    echo   "os_blacklist": ["windows"]
    echo }
)

copy /Y "%REPO_ROOT%\tests\run_native_tests.cmd" "%TEST_TMP%\tests\run_native_tests.cmd" >nul
if exist "%REPO_ROOT%\tests\update_results.cmd" (
    copy /Y "%REPO_ROOT%\tests\update_results.cmd" "%TEST_TMP%\tests\update_results.cmd" >nul
)

> "%TEST_TMP%\README.md" (
    echo # Mock Project
    echo.
    echo ## Supported Components
    echo.
    echo ^| Component ^| Linux ^(apk^) ^| Linux ^(deb^) ^| Linux ^(rpm^) ^| Windows ^| SunOS ^| FreeBSD ^|
    echo ^|---^|---^|---^|---^|---^|---^|
    echo ^| `compA` ^| ❓ ^| ❓ ^| ❓ ^| - ^| - ^| - ^|
    echo ^| `compB` ^| ❓ ^| ❓ ^| ❓ ^| - ^| - ^| - ^|
    echo.
    echo ## License
    echo MIT
)

:: Test 1: Dry run with compA
pushd "%TEST_TMP%"
call "%TEST_TMP%\tests\run_native_tests.cmd" --dry-run compA
popd

if not exist "%TEST_TMP%\tests_tmp\compA.windows.success" (
    echo [ERROR] compA.windows.success was not created
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

:: Test 2: Dry run with category flag
pushd "%TEST_TMP%"
call "%TEST_TMP%\tests\run_native_tests.cmd" --dry-run --category catA
popd

if not exist "%TEST_TMP%\tests_tmp\compA.windows.stdout" (
    echo [ERROR] compA.windows.stdout was not created from category run
    rmdir /s /q "%TEST_TMP%" >nul 2>&1
    exit /b 1
)

rmdir /s /q "%TEST_TMP%" >nul 2>&1
echo run_native_tests.cmd tests passed successfully.
goto :eof
