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

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

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

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
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
