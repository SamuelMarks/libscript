@echo off
:: # test_harvest_licenses.cmd
:: ## Overview
:: Automated unit and integration tests for universal dependency license harvesting on Windows.
:: ## Usage
:: .\tests\test_harvest_licenses.cmd

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

if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
goto :main

:: ## show_help
:: Displays usage instructions and available options.
:show_help
echo Usage: %~nx0
echo Runs automated tests for universal dependency license harvesting on Windows.
exit /b 0

:: ## main
:: Executes the license harvester unit and integration test suite on Windows.
:main
set "HARVESTER=!LIBSCRIPT_ROOT_DIR!\packaging\harvest_licenses.cmd"
set "TMP_BASE=%TEMP%\test_harvest_licenses_%RANDOM%"
if not exist "!TMP_BASE!" mkdir "!TMP_BASE!"

echo === Test 1: Leaf Package License Harvesting (SQLite) ===
set "OUT_SQLITE=!TMP_BASE!\sqlite_licenses"
call "!HARVESTER!" "_lib\databases\sqlite" --out-dir "!OUT_SQLITE!" --force
if errorlevel 1 (
    echo [FAIL] harvest_licenses.cmd failed for sqlite >&2
    rmdir /s /q "!TMP_BASE!" >nul 2>&1
    exit /b 1
)

for %%F in ("!OUT_SQLITE!\licenses_manifest.json" "!OUT_SQLITE!\combined_licenses.txt" "!OUT_SQLITE!\combined_licenses.rtf" "!OUT_SQLITE!\sqlite.txt" "!OUT_SQLITE!\sqlite.rtf") do (
    if not exist "%%~F" (
        echo [FAIL] Missing expected output artifact: %%~F >&2
        rmdir /s /q "!TMP_BASE!" >nul 2>&1
        exit /b 1
    )
    echo [PASS] Exists and non-empty: %%~nxF
)

echo === Test 2: Composite Stack License Harvesting (WordPress) ===
set "OUT_WP=!TMP_BASE!\wordpress_licenses"
call "!HARVESTER!" "_lib\web-apps\wordpress" --out-dir "!OUT_WP!" --force
if errorlevel 1 (
    echo [FAIL] harvest_licenses.cmd failed for wordpress >&2
    rmdir /s /q "!TMP_BASE!" >nul 2>&1
    exit /b 1
)

for %%C in (wordpress php mariadb caddy) do (
    if not exist "!OUT_WP!\%%C.txt" (
        echo [FAIL] Missing %%C.txt in WordPress license harvest >&2
        rmdir /s /q "!TMP_BASE!" >nul 2>&1
        exit /b 1
    )
    if not exist "!OUT_WP!\%%C.rtf" (
        echo [FAIL] Missing %%C.rtf in WordPress license harvest >&2
        rmdir /s /q "!TMP_BASE!" >nul 2>&1
        exit /b 1
    )
    echo [PASS] WordPress dependency license harvested: %%C
)

echo === Test 3: Composite Stack License Harvesting (Open edX) ===
set "OUT_EDX=!TMP_BASE!\openedx_licenses"
call "!HARVESTER!" "_lib\web-apps\openedx" --out-dir "!OUT_EDX!" --force
if errorlevel 1 (
    echo [FAIL] harvest_licenses.cmd failed for openedx >&2
    rmdir /s /q "!TMP_BASE!" >nul 2>&1
    exit /b 1
)

for %%C in (openedx python nodejs mysql redis mongodb meilisearch caddy git) do (
    if not exist "!OUT_EDX!\%%C.txt" (
        echo [FAIL] Missing %%C.txt in Open edX license harvest >&2
        rmdir /s /q "!TMP_BASE!" >nul 2>&1
        exit /b 1
    )
    if not exist "!OUT_EDX!\%%C.rtf" (
        echo [FAIL] Missing %%C.rtf in Open edX license harvest >&2
        rmdir /s /q "!TMP_BASE!" >nul 2>&1
        exit /b 1
    )
    echo [PASS] Open edX dependency license harvested: %%C
)

echo === Test 4: Idempotency Verification ===
call "!HARVESTER!" "_lib\databases\sqlite" --out-dir "!OUT_SQLITE!"
if errorlevel 1 (
    echo [FAIL] Idempotent re-run of harvest_licenses.cmd failed >&2
    rmdir /s /q "!TMP_BASE!" >nul 2>&1
    exit /b 1
)
echo [PASS] Idempotency confirmed on subsequent execution

rmdir /s /q "!TMP_BASE!" >nul 2>&1
echo === All license harvester tests completed successfully! ===
exit /b 0
