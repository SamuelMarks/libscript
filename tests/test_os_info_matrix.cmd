@echo off
:: # test_os_info_matrix.cmd
::
:: ## Overview
:: Hermetic Windows Batch test suite verifying `_lib\_common\os_info.cmd` across architecture variants (AMD64, ARM64, x86), 2x idempotent sourcing, `INIT_SYS=windows-scm`, and absence of `NGINX_SERVERS_ROOT` side-effect leaks.
::
:: ## Usage
:: call tests\test_os_info_matrix.cmd

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "SAVED_ARCH=%PROCESSOR_ARCHITECTURE%"

call :check_arch "AMD64" "x86_64" "amd64"
if errorlevel 1 exit /b 1

call :check_arch "ARM64" "aarch64" "arm64"
if errorlevel 1 exit /b 1

call :check_arch "x86" "i686" "386"
if errorlevel 1 exit /b 1

set "PROCESSOR_ARCHITECTURE=%SAVED_ARCH%"
set "NGINX_SERVERS_ROOT="
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\os_info.cmd"
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\os_info.cmd"

if not "!TARGET_OS!"=="windows" (
    call :fail_test "Expected TARGET_OS=windows, got !TARGET_OS!"
    exit /b 1
)
if not "!INIT_SYS!"=="windows-scm" (
    call :fail_test "Expected INIT_SYS=windows-scm, got !INIT_SYS!"
    exit /b 1
)
if defined NGINX_SERVERS_ROOT (
    call :fail_test "os_info.cmd leaked NGINX_SERVERS_ROOT=!NGINX_SERVERS_ROOT!"
    exit /b 1
)

echo [PASS] All Windows architecture mappings ^(AMD64, ARM64, x86^) resolved cleanly.
echo [PASS] Windows os_info.cmd is side-effect-free, idempotent ^(2x^), and exports INIT_SYS=windows-scm.
exit /b 0

:: ## check_arch
:: Verifies PROCESSOR_ARCHITECTURE maps to expected ARCH and ARCH_ALT across os_info.cmd.
:check_arch
set "PROCESSOR_ARCHITECTURE=%~1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\os_info.cmd"
if not "!ARCH!"=="%~2" (
    call :fail_test "Arch %~1: expected ARCH=%~2, got !ARCH!"
    exit /b 1
)
if not "!ARCH_ALT!"=="%~3" (
    call :fail_test "Arch %~1: expected ARCH_ALT=%~3, got !ARCH_ALT!"
    exit /b 1
)
exit /b 0

:: ## fail_test
:: Prints a failure diagnostic to stderr and returns exit code 1.
:fail_test
echo [FAIL] %~1 >&2
exit /b 1
