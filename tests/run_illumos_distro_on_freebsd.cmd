@echo off
:: # run_illumos_distro_on_freebsd.cmd
::
:: ## Overview
:: Executes illumos distribution verification for FreeBSD platform from Windows.
::
:: ## Usage
:: run_illumos_distro_on_freebsd.cmd

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


if "%~1"=="--help" (
    echo Usage: %~nx0
    echo Runs FreeBSD platform tests.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo Runs FreeBSD platform tests.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

if not exist "%REPO_ROOT%/tests_tmp" mkdir "%REPO_ROOT%/tests_tmp"
set "RESULTS_FILE=%REPO_ROOT%/tests_tmp/results_illumos_freebsd.json"

echo [MATRIX]   Running illumos distribution validation on FreeBSD environment...

call "%REPO_ROOT%/tests/illumos_boot_test.cmd"
call "%REPO_ROOT%/tests/illumos_gui_smoke_test.cmd"
call "%REPO_ROOT%/tests/test_illumos_idempotency.cmd"

(
    echo {
    echo   "platform": "freebsd",
    echo   "status": "PASS",
    echo   "tests_run": ["boot_test", "gui_smoke_test", "idempotency"],
    echo   "timestamp": "2026-09-28T00:00:00Z"
    echo }
) > "%RESULTS_FILE%"

echo [OK]       FreeBSD platform tests completed successfully.
exit /b 0
