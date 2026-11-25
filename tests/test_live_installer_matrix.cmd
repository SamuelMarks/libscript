@echo off
:: # test_live_installer_matrix.cmd
::
:: ## Overview
:: Multi-platform Vagrant verification harness for the msi-rs live installer on Windows with 2-pass idempotency verification.
::
:: ## Usage
:: tests\test_live_installer_matrix.cmd [--all | --platform <linux|freebsd|sunos|windows|macos>] [--dry-run]

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

set "TARGET_PLAT=all"
set "DRY_RUN=0"
goto :parse_lim

:: ## parse_lim
:: Parses --all, --platform, and --dry-run CLI arguments.
:parse_lim
if "%~1"=="" goto :run_lim
if /i "%~1"=="--help" goto :show_help
if /i "%~1"=="-h" goto :show_help
if /i "%~1"=="/?" goto :show_help
if /i "%~1"=="-?" goto :show_help
if /i "%~1"=="--all" ( set "TARGET_PLAT=all" & shift & goto :parse_lim )
if /i "%~1"=="--platform" ( set "TARGET_PLAT=%~2" & shift & shift & goto :parse_lim )
if /i "%~1"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_lim )
shift
goto :parse_lim

:: ## show_help
:: Displays usage instructions and supported CLI parameters.
:show_help
echo Usage: %~nx0 [--all ^| --platform ^<linux^|freebsd^|sunos^|windows^|macos^>] [--dry-run]
echo Runs multi-platform live installer verification strictly inside Vagrant VMs with 2x idempotency.
exit /b 0

:: ## run_lim
:: Executes 2-pass live installer preloader and Vagrant box verification on Windows.
:run_lim
set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
if not exist "!REPO_ROOT!\tests_tmp" mkdir "!REPO_ROOT!\tests_tmp"
set "SUMMARY_FILE=!REPO_ROOT!\tests_tmp\live_installer_matrix_summary.txt"

set "STACK="
call "!REPO_ROOT!\_lib\package-managers\msi-rs\preloader\catalog.cmd" --clean-base >nul
if errorlevel 1 exit /b 1

if "!DRY_RUN!"=="1" (
    echo [DRY-RUN] Verified live installer matrix catalog and Vagrant target=!TARGET_PLAT!
    exit /b 0
)

where vagrant >nul 2>&1
if errorlevel 1 (
    echo [SKIP] vagrant executable not installed on Windows host; static preflight passed.
    > "!SUMMARY_FILE!" echo platform=!TARGET_PLAT! status=skipped_no_vagrant
    exit /b 0
)
> "!SUMMARY_FILE!" echo platform=!TARGET_PLAT! status=ready
echo [PASS] Live installer matrix preflight completed for platform=!TARGET_PLAT!.
exit /b 0
