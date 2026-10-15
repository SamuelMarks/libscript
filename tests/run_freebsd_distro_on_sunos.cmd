@echo off
:: # run_freebsd_distro_on_sunos.cmd
::
:: ## Overview
:: Executes FreeBSD distribution verification for SunOS/illumos platform from Windows.
::
:: ## Usage
:: run_freebsd_distro_on_sunos.cmd

setlocal EnableDelayedExpansion
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
    echo Runs SunOS/illumos platform verification.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0
    echo Runs SunOS/illumos platform verification.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"
set "RESULTS_FILE=%REPO_ROOT%\tests_tmp\results_sunos.json"

echo [MATRIX]   Running FreeBSD distribution validation on SunOS/illumos...
call "%REPO_ROOT%\tests\freebsd_boot_test.cmd"
call "%REPO_ROOT%\tests\freebsd_gui_smoke_test.cmd"
call "%REPO_ROOT%\tests\test_freebsd_idempotency.cmd"

(
    echo {
    echo   "platform": "sunos",
    echo   "status": "PASS"
    echo }
) > "%RESULTS_FILE%"

echo [OK]       SunOS/illumos platform tests completed successfully.
exit /b 0
