@echo off
:: # test_shellcheck_vm_and_hooks.cmd
::
:: ## Overview
:: End-to-end Windows Batch behavioral test suite for the ShellCheck native version manager
:: (`_lib\toolchains\shellcheck`) and automatic pre-commit hook bootstrapping when `shellcheck`
:: is nonexistent on `PATH`.
::
:: ## Usage
:: tests\test_shellcheck_vm_and_hooks.cmd

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
cd /d "%LIBSCRIPT_ROOT_DIR%"

set "FAILURES=0"
set "CHECKS=0"

echo === 1. Auditing _lib\toolchains\shellcheck Standards ^& Companion Parity ===
call "devtools\audit\audit_version_manager.cmd" "_lib\toolchains\shellcheck" >nul 2>&1
if errorlevel 1 (
    call :fail_check "_lib\toolchains\shellcheck failed Version Manager Contract audit"
) else (
    call :pass_check "_lib\toolchains\shellcheck satisfies Version Manager Contract audit"
)

set "_MISSING_CMD=0"
for %%F in ("_lib\toolchains\shellcheck\*.sh") do (
    if not exist "_lib\toolchains\shellcheck\%%~nF.cmd" (
        call :fail_check "Missing Windows Batch companion for %%~nxF"
        set "_MISSING_CMD=1"
    )
)
if "!_MISSING_CMD!"=="0" (
    call :pass_check "1:1 .sh / .cmd companion parity verified across _lib\toolchains\shellcheck"
)

echo === 2. Testing Isolation, Idempotency ^& Lifecycle Verbs ===
set "TEST_WS=%TEMP%\libscript_sc_vm_test_%RANDOM%"
if not exist "!TEST_WS!" mkdir "!TEST_WS!"
set "FAKE_LS_HOME=!TEST_WS!\ls_home"
if not exist "!FAKE_LS_HOME!" mkdir "!FAKE_LS_HOME!"

set "LIBSCRIPT_HOME=!FAKE_LS_HOME!"
set "LIBSCRIPT_NEVER_REFRESH_CHECKSUM_DB=1"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install shellcheck 0.11.0
if errorlevel 1 (
    call :fail_check "Initial install of shellcheck 0.11.0 failed"
) else if exist "!FAKE_LS_HOME!\shellcheck\0.11.0\bin\shellcheck.exe" (
    call :pass_check "Installed shellcheck 0.11.0 into isolated LIBSCRIPT_HOME"
) else (
    call :fail_check "shellcheck.exe missing in !FAKE_LS_HOME!\shellcheck\0.11.0\bin"
)

set "IDEMP_LOG=!TEST_WS!\idemp.log"
set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" install shellcheck 0.11.0 > "!IDEMP_LOG!" 2>&1
findstr /I /C:"already installed" "!IDEMP_LOG!" >nul 2>&1
if errorlevel 1 (
    call :fail_check "Second install of shellcheck 0.11.0 did not hit idempotent early exit"
) else (
    call :pass_check "Second install of shellcheck 0.11.0 exited idempotently"
)

set "STACK="
call "%LIBSCRIPT_ROOT_DIR%\libscript.cmd" test shellcheck
if errorlevel 1 (
    call :fail_check "shellcheck smoke test failed"
) else (
    call :pass_check "shellcheck smoke test passed"
)

rmdir /s /q "!TEST_WS!" >nul 2>&1

if not "!FAILURES!"=="0" (
    echo [FAIL] ShellCheck Windows Suite failed (!FAILURES!/!CHECKS! checks failed) 1>&2
    exit /b 1
)

echo === All !CHECKS! ShellCheck Windows Checks Passed! ===
exit /b 0

:: ## pass_check
:: Records a passing assertion in the Windows test suite.
:pass_check
set /a CHECKS+=1
echo [PASS] %~1
exit /b 0

:: ## fail_check
:: Records a failing assertion in the Windows test suite.
:fail_check
set /a CHECKS+=1
set /a FAILURES+=1
echo [FAIL] %~1 1>&2
exit /b 0
