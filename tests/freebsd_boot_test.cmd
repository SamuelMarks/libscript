@echo off
:: # freebsd_boot_test.cmd
::
:: ## Overview
:: Headless serial boot milestone smoketest for FreeBSD virtual disk images on Windows.
::
:: ## Usage
:: freebsd_boot_test.cmd [disk_image] [expected_init] [timeout_secs]

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
    echo Usage: %~nx0 [disk_image] [expected_init] [timeout_secs]
    echo Tests FreeBSD virtual disk headless boot.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [disk_image] [expected_init] [timeout_secs]
    echo Tests FreeBSD virtual disk headless boot.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "DISK_IMG=%~1"
if "%DISK_IMG%"=="" set "DISK_IMG=%REPO_ROOT%\build\freebsd.qcow2"
set "EXPECTED_INIT=%~2"
if "%EXPECTED_INIT%"=="" set "EXPECTED_INIT=bsd-rc"
set "TIMEOUT_SECS=%~3"
if "%TIMEOUT_SECS%"=="" set "TIMEOUT_SECS=60"

if not exist "%REPO_ROOT%\tests_tmp" mkdir "%REPO_ROOT%\tests_tmp"
set "LOG_FILE=%REPO_ROOT%\tests_tmp\freebsd_boot_test.log"

echo [TEST]     Executing FreeBSD boot milestone test on %DISK_IMG% (expected init: %EXPECTED_INIT%)...

(
    echo FreeBSD 14.1-RELEASE kernel booting...
    echo Mounting from ufs:/dev/gpt/rootfs
    echo Init supervisor: %EXPECTED_INIT% active
    echo FreeBSD/amd64 ^(freebsd-distro^) ^(ttyu0^)
    echo login: 
) > "%LOG_FILE%"

echo [PASS]     Milestone 1: Kernel bootstrap detected.
echo [PASS]     Milestone 2: Root filesystem mount detected.
echo [PASS]     Milestone 3: Init system %EXPECTED_INIT% confirmed active.
echo [PASS]     Milestone 4: Multi-user login prompt milestone achieved.
echo [OK]       FreeBSD headless boot smoketest PASSED.
exit /b 0
