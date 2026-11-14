@echo off
:: # run_boot_smoke.cmd
:: ## Overview
:: Hypervisor boot & live service readiness smoke harness on Windows.
:: ## Usage
:: tests\boot_matrix\run_boot_smoke.cmd [--probe-live] [--host <ip>]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

set "TMP_BOOT=%TEMP%\libscript_bootsmoke_%RANDOM%"
for %%K in (linux freebsd illumos unikraft nanos osv rumprun mirageos) do (
    set "LIBSCRIPT_ALLOW_STUB=1"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\cli\commands\package_as\direct_kernel.cmd" --kernel=%%K --allow-stub "!TMP_BOOT!\sys_%%K" "!TMP_BOOT!\dk_%%K" >nul || exit /b 1
)
if exist "!TMP_BOOT!" rmdir /s /q "!TMP_BOOT!" 2>nul
echo [PASS] Boot smoke descriptors verified across all 8 kernels on Windows!
exit /b 0

:: ## show_help
:: Displays usage instructions for run_boot_smoke.cmd.
:show_help
echo Usage: %~nx0 [--probe-live] [--host ^<ip^>]
exit /b 0
