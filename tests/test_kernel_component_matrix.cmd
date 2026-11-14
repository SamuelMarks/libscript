@echo off
:: # test_kernel_component_matrix.cmd
:: ## Overview
:: End-to-end verification matrix across kernels, component sets, and formats on Windows.
:: ## Usage
:: tests\test_kernel_component_matrix.cmd

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

for %%K in (linux-glibc linux-musl freebsd illumos osv nanos) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" build-image --kernel=%%K --format=qcow2 --components=redis,postgres,openedx --dry-run >nul || exit /b 1
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" build-image --kernel=unikraft --format=direct-kernel --components=redis --dry-run >nul || exit /b 1

echo [PASS] Kernel x Component x Format Matrix PASSED on Windows!
exit /b 0

:: ## show_help
:: Displays usage instructions for test_kernel_component_matrix.cmd.
:show_help
echo Usage: %~nx0
exit /b 0
