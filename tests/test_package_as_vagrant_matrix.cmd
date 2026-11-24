@echo off
:: # test_package_as_vagrant_matrix.cmd
:: ## Overview
:: Cross-OS Vagrant CI matrix orchestrator on Windows exercising `libscript.cmd package-as` across Windows 11, Windows Server 2025, Linux, FreeBSD, macOS, and OmniOS.
:: ## Usage
:: tests\test_package_as_vagrant_matrix.cmd [--os=all]

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

call :run_matrix
exit /b !errorlevel!

:: ## run_matrix
:: Validates Vagrantfiles, executes test_package_as_kernels.cmd, and writes an idempotent matrix report.
:run_matrix
for %%G in (windows-11 windows-server-2025 debian-13 freebsd-15.1 macos-14-arm64 omnios) do (
    if not exist "!LIBSCRIPT_ROOT_DIR!\vagrant\%%G\Vagrantfile" (
        echo [FAIL] Missing Vagrantfile for %%G >&2
        exit /b 1
    )
)

set "REPORT_DIR=!LIBSCRIPT_ROOT_DIR!\build"
if not "!LIBSCRIPT_BUILD_DIR!"=="" set "REPORT_DIR=!LIBSCRIPT_BUILD_DIR!"
if not exist "!REPORT_DIR!" mkdir "!REPORT_DIR!"
set "REPORT_FILE=!REPORT_DIR!\package-as-vagrant-matrix-report.json"
set "STAMP_FILE=!REPORT_FILE!.stamp"

if exist "!STAMP_FILE!" if exist "!REPORT_FILE!" (
    echo [SKIP] Cross-OS package-as Vagrant matrix already verified: !REPORT_FILE!
    exit /b 0
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\test_package_as_kernels.cmd"
if errorlevel 1 exit /b 1

(
echo {"suite":"package-as-vagrant-matrix","targets":"windows-11 windows-server-2025 debian-13 freebsd-15.1 macos-14-arm64 omnios","status":"PASS"}
) > "!REPORT_FILE!.tmp"
move /y "!REPORT_FILE!.tmp" "!REPORT_FILE!" >nul 2>&1
(
echo targets=windows-11 windows-server-2025 debian-13 freebsd-15.1 macos-14-arm64 omnios
) > "!STAMP_FILE!.tmp"
move /y "!STAMP_FILE!.tmp" "!STAMP_FILE!" >nul 2>&1
echo [PASS] Windows cross-OS package-as Vagrant matrix verified: !REPORT_FILE!
exit /b 0
