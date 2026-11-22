@echo off
:: # test_tier_architecture.cmd
:: ## Overview
:: End-to-end Windows Batch verification suite for T0-T5 + Orthogonal Planes boundaries,
:: negative synthetic fixtures, CLI dispatch, T2 use-rejection, and 2x idempotency.
:: ## Usage
:: tests\test_tier_architecture.cmd

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

set "TEST_TMP=%TEMP%\ls_tier_arch_%RANDOM%"
if not exist "!TEST_TMP!" mkdir "!TEST_TMP!"

echo === 1. Clean Repository T0-T5 Audit (2x Idempotent) ===
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_tiers.cmd" --all
if errorlevel 1 goto :fail
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_tiers.cmd" --all
if errorlevel 1 goto :fail

echo === 2. Negative Fixture Tests ===
set "FIX_UP=!TEST_TMP!\fix_up"
if not exist "!FIX_UP!\_lib\utilities\foo" mkdir "!FIX_UP!\_lib\utilities\foo"
type nul > "!FIX_UP!\libscript.cmd"
echo {"name":"foo","tier":"T1","provides":["foo"],"capabilities":["userland-package"]} > "!FIX_UP!\_lib\utilities\foo\manifest.json"
echo call infrastructure\cli.cmd > "!FIX_UP!\_lib\utilities\foo\setup.cmd"
call "!LIBSCRIPT_ROOT_DIR!\devtools\audit\audit_tiers.cmd" --root "!FIX_UP!" >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] audit_tiers.cmd failed to reject T1 -^> T4 upward import >&2
    goto :fail
)
echo [PASS] Rejected T1 -^> T4 upward import fixture.

echo === 3. T2 Use Guard ^& T4/T5/Plane A/B Routing ===
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" use glibc latest >nul 2>&1
if "!errorlevel!" neq "2" (
    echo [FAIL] Expected exit code 2 when invoking use on T2 recipe glibc >&2
    goto :fail
)
echo [PASS] T2 sysroot-only recipe ^(glibc^) rejected unprivileged use switching.

call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" trait list >nul
if errorlevel 1 goto :fail
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" experiment list >nul
if errorlevel 1 goto :fail

rmdir /s /q "!TEST_TMP!" 2>nul
echo === All T0-T5 + Orthogonal Planes Architecture Tests Passed^^! ===
exit /b 0

:: ## fail
:: Cleans up temporary test state and exits 1.
:fail
rmdir /s /q "!TEST_TMP!" 2>nul
exit /b 1
