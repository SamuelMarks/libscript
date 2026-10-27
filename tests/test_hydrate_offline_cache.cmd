@echo off
:: # test_hydrate_offline_cache.cmd
setlocal EnableDelayedExpansion
:: # tests/test_hydrate_offline_cache.cmd
::
:: ## Overview
:: Windows Batch unit test runner for the LibScript cache hydration engine.
::
:: ## Usage
:: call tests\test_hydrate_offline_cache.cmd

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

for %%I in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fI"

set "TEST_TMP_DIR=%LIBSCRIPT_ROOT_DIR%\tests_tmp\test_hydrate_%RANDOM%"
if not exist "%TEST_TMP_DIR%" mkdir "%TEST_TMP_DIR%"

echo === Testing LibScript Offline Cache Hydration Engine (Windows) ===

set "SRC_DIR=%TEST_TMP_DIR%\upstream"
if not exist "%SRC_DIR%" mkdir "%SRC_DIR%"
echo LibScript Offline Test Content Windows > "%SRC_DIR%\dummy-runtime.zip"

for /f "tokens=*" %%H in ('powershell -Command "(Get-FileHash -Path '%SRC_DIR%\dummy-runtime.zip' -Algorithm SHA256).Hash.ToLower()"') do set "DUMMY_SHA256=%%H"

set "TEST_MANIFEST=%TEST_TMP_DIR%\test_bundle.json"
(
echo {
echo   "name": "test-stack",
echo   "version": "1.0.0",
echo   "runtimes": {
echo     "test_rt": {
echo       "name": "test_rt",
echo       "version": "1.0.0",
echo       "filename": "dummy-runtime.zip",
echo       "url": "file:///%SRC_DIR:\=/%/dummy-runtime.zip",
echo       "sha256": "%DUMMY_SHA256%"
echo     }
echo   },
echo   "databases": {},
echo   "wheels": { "target_dir": "cache/wheels", "packages": [] },
echo   "codebase": {},
echo   "checksums": { "dummy-runtime.zip": "%DUMMY_SHA256%" }
echo }
) > "%TEST_MANIFEST%"

set "CACHE_TARGET=%TEST_TMP_DIR%\cache"

:: Test 1: Verify-only on empty cache
echo [TEST 1/3] Verifying --verify-only fails on empty cache...
call "%LIBSCRIPT_ROOT_DIR%\packaging\hydrate_offline_cache.cmd" --manifest "%TEST_MANIFEST%" --cache-dir "%CACHE_TARGET%" --verify-only >nul 2>&1
if errorlevel 1 (
    echo [PASS] Verify-only correctly reports non-zero exit code on empty cache
) else (
    echo [FAIL] Expected non-zero exit code on empty cache >&2
    exit /b 1
)

:: Test 2: Hydrate cache
echo [TEST 2/3] Verifying hydration...
call "%LIBSCRIPT_ROOT_DIR%\packaging\hydrate_offline_cache.cmd" --manifest "%TEST_MANIFEST%" --cache-dir "%CACHE_TARGET%" > "%TEST_TMP_DIR%\t2.log" 2>&1
if exist "%CACHE_TARGET%\runtimes\dummy-runtime.zip" (
    echo [PASS] Artifact successfully hydrated
) else (
    echo [FAIL] Hydration did not produce expected artifact >&2
    type "%TEST_TMP_DIR%\t2.log" >&2
    exit /b 1
)

:: Test 3: Verify-only on hydrated cache
echo [TEST 3/3] Verifying --verify-only succeeds on intact cache...
call "%LIBSCRIPT_ROOT_DIR%\packaging\hydrate_offline_cache.cmd" --manifest "%TEST_MANIFEST%" --cache-dir "%CACHE_TARGET%" --verify-only >nul 2>&1
if not errorlevel 1 (
    echo [PASS] Intact cache verified successfully
) else (
    echo [FAIL] Verify-only failed on intact cache >&2
    exit /b 1
)

echo ==========================================================
echo [SUCCESS] All Windows cache hydration unit tests passed!
echo ==========================================================

rmdir /s /q "%TEST_TMP_DIR%" 2>nul
exit /b 0
