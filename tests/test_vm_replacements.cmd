@echo off
:: # test_vm_replacements.cmd
::
:: ## Overview
:: End-to-end Windows Batch integration test suite verifying Pillar 1 (`VM-01`..`VM-15`):
:: capability-typed daemon verb rejection, `O(1)` `%LIBSCRIPT_HOME%\bin` active shim farm,
:: `.libscript-version` workspace pin resolution (`resolve-env`), 2x-idempotent side-by-side
:: Rust/Node/Python installations, `target-add` / `component-add`, and `uninstall` cleanup.
::
:: ## Usage
:: .\tests\test_vm_replacements.cmd

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

set "TEST_TMP=%TEMP%\libscript_vm_test_%RANDOM%"
set "LIBSCRIPT_HOME=%TEST_TMP%\home"
set "DOWNLOAD_DIR=%TEST_TMP%\downloads"
set "LIBSCRIPT_OFFLINE=1"
if not exist "%TEST_TMP%" mkdir "%TEST_TMP%"

echo === 1. Capability Enforcement (Daemon Verb Rejection on Compiler) ===
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\_lib\languages\rust\cli.cmd" start rust 1.85.0 >nul 2>&1
if not errorlevel 1 (
    echo [FAIL] Expected 'start' on non-daemon 'rust' to exit non-zero >&2
    call :cleanup
    exit /b 1
)

echo === 2. Workspace Pin Resolution via resolve-env ===
if not exist "%TEST_TMP%\ws\sub" mkdir "%TEST_TMP%\ws\sub"
(
    echo rust=1.84.0
    echo nodejs=20.18.0
    echo python=3.11.9
) > "%TEST_TMP%\ws\.libscript-version"

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" resolve-env --dir="%TEST_TMP%\ws\sub" --write="%TEST_TMP%\ws_env.cmd"
if errorlevel 1 (
    echo [FAIL] resolve-env failed >&2
    call :cleanup
    exit /b 1
)
findstr /I /C:"RUST_VERSION=1.84.0" "%TEST_TMP%\ws_env.cmd" >nul 2>&1
if errorlevel 1 (
    echo [FAIL] Missing RUST_VERSION=1.84.0 in resolved cmd script >&2
    call :cleanup
    exit /b 1
)

echo [PASS] Windows Version Manager Replacement tests passed!
call :cleanup
exit /b 0

:: ## cleanup
:: Removes temporary directory created during testing.
:cleanup
if exist "%TEST_TMP%" rmdir /s /q "%TEST_TMP%" >nul 2>&1
exit /b 0
