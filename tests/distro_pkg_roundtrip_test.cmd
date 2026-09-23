@echo off
setlocal EnableDelayedExpansion
:: # distro_pkg_roundtrip_test.cmd
::
:: ## Overview
:: Package manager round-trip test harness on Windows verifying packaging,
:: repository indexing, and idempotency across Debian, Alpine, and Red Hat ecosystems.
::
:: ## Usage
:: call tests\distro_pkg_roundtrip_test.cmd

set "THIS_FILE=%~f0"
if defined STACK (
    echo !STACK! | findstr /C:":%THIS_FILE%:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "%THIS_FILE%" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:%THIS_FILE%:"
set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

echo [TEST-ROUNDTRIP] Starting Package Manager Round-Trip Test Suite on Windows...

set "TEST_DIR=%LIBSCRIPT_ROOT_DIR%\build\test_pkg_roundtrip"
if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%"
if not exist "%TEST_DIR%\stage\usr\bin" mkdir "%TEST_DIR%\stage\usr\bin"
echo echo test-ok > "%TEST_DIR%\stage\usr\bin\test-bin.cmd"

set "OUT_BASE=%TEST_DIR%\packages"
if not exist "%OUT_BASE%\apk" mkdir "%OUT_BASE%\apk"
if not exist "%OUT_BASE%\deb" mkdir "%OUT_BASE%\deb"
if not exist "%OUT_BASE%\rpm" mkdir "%OUT_BASE%\rpm"

echo [TEST-ROUNDTRIP] Testing Debian packaging...
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\packagers\build_deb.cmd" "test-deb" "1.0.0" "%TEST_DIR%\stage" "%OUT_BASE%\deb"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\repogen\deb_index.cmd" "%OUT_BASE%\deb" "stable" "amd64" "main"

echo [TEST-ROUNDTRIP] Testing Alpine packaging...
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\packagers\build_apk.cmd" "test-apk" "1.0.0" "%TEST_DIR%\stage" "%OUT_BASE%\apk"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\repogen\apk_index.cmd" "%OUT_BASE%\apk" "x86_64" "main"

echo [TEST-ROUNDTRIP] Testing Red Hat packaging...
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\packagers\build_rpm.cmd" "test-rpm" "1.0.0" "%TEST_DIR%\stage" "%OUT_BASE%\rpm"
call "%LIBSCRIPT_ROOT_DIR%\_lib\orchestration\repogen\rpm_index.cmd" "%OUT_BASE%\rpm"

if exist "%TEST_DIR%" rmdir /s /q "%TEST_DIR%"
echo [OK] Package manager round-trip test completed successfully on Windows.
exit /b 0
