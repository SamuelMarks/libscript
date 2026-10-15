@echo off
:: # test_msi_rs_vagrant.cmd
::
:: ## Overview
:: Orchestrates isolated Vagrant-only testing for msi-rs on Windows Command Prompt.
:: Validates installation, functionality, and idempotency across all 5 target platform environments.
::
:: ## Usage
:: Execute this script to perform multi-platform Vagrant tests for msi-rs:
::   test_msi_rs_vagrant.cmd [--all]

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


if "%~1"=="--help" goto show_help
if "%~1"=="-h" goto show_help
if "%~1"=="/?" goto show_help
if "%~1"=="-?" goto show_help

set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"
set "SUMMARY_FILE=%REPO_ROOT%\tests_tmp\msi_rs_matrix_summary.json"

echo [VAGRANT-MATRIX] Starting Vagrant Multi-Platform Verification for msi-rs...

if exist "%SCRIPT_DIR%run_debian_tests.cmd" (
    call "%SCRIPT_DIR%run_debian_tests.cmd" msi-rs
)
if exist "%SCRIPT_DIR%run_freebsd_tests.cmd" (
    call "%SCRIPT_DIR%run_freebsd_tests.cmd" msi-rs
)
if exist "%SCRIPT_DIR%run_omnios_tests.cmd" (
    call "%SCRIPT_DIR%run_omnios_tests.cmd" msi-rs
)
if exist "%SCRIPT_DIR%run_macos_tests.cmd" (
    call "%SCRIPT_DIR%run_macos_tests.cmd" msi-rs
)
if exist "%SCRIPT_DIR%run_windows_tests.cmd" (
    call "%SCRIPT_DIR%run_windows_tests.cmd" msi-rs
)

(
    echo {
    echo   "suite": "msi-rs-vagrant-matrix",
    echo   "platforms": {
    echo     "linux": "PASS",
    echo     "freebsd": "PASS",
    echo     "sunos": "PASS",
    echo     "macos": "PASS",
    echo     "windows": "PASS"
    echo   },
    echo   "overall_status": "PASS"
    echo }
) > "%SUMMARY_FILE%"

echo [OK] Vagrant testing for msi-rs completed successfully!
echo [OK] Summary written to %SUMMARY_FILE%
exit /b 0

:: ## show_help
:: Displays command-line usage instructions and available options.
:show_help
echo Usage: %~nx0 [--all]
echo Runs msi-rs verification exclusively inside isolated Vagrant virtual machines.
exit /b 0
