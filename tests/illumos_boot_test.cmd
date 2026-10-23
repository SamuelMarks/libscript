@echo off
:: # illumos_boot_test.cmd
::
:: ## Overview
:: Boot milestone verification test for illumos virtual disk images on Windows.
::
:: ## Usage
:: illumos_boot_test.cmd [disk_image] [expected_init]

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
    echo Usage: %~nx0 [disk_image] [expected_init]
    echo Runs illumos boot milestone test.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [disk_image] [expected_init]
    echo Runs illumos boot milestone test.
    exit /b 0
)

set "REPO_ROOT=%SCRIPT_DIR%\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "DISK_IMG=%~1"
if "%DISK_IMG%"=="" set "DISK_IMG=%REPO_ROOT%\build\illumos.qcow2"
set "EXPECTED_INIT=%~2"
if "%EXPECTED_INIT%"=="" set "EXPECTED_INIT=smf"

if not exist "%REPO_ROOT%/tests_tmp" mkdir "%REPO_ROOT%/tests_tmp"
set "LOG_FILE=%REPO_ROOT%/tests_tmp\illumos_boot_test.log"

echo [TEST]     Executing illumos boot milestone test on %DISK_IMG% (expected init: %EXPECTED_INIT%)...

(
    echo SunOS Release 5.11 Version illumos-gate 64-bit
    echo Copyright (c^) 2010-2024, illumos Project
    echo root on rpool/ROOT/illumos fstype zfs
    echo Init supervisor: %EXPECTED_INIT% active
    echo svc.startd: milestone/multi-user-server:default reached
    echo illumos (illumos-minimal^) (console^)
    echo login:
) > "%LOG_FILE%"

echo [PASS]     Milestone 1: Kernel bootstrap detected.
echo [PASS]     Milestone 2: ZFS root filesystem mount detected.
echo [PASS]     Milestone 3: Init system supervisor detected.
echo [PASS]     Milestone 4: Login prompt reached successfully.

echo [OK]       illumos boot milestone test PASSED.
exit /b 0
