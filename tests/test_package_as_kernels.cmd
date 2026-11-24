@echo off
:: # test_package_as_kernels.cmd
::
:: ## Overview
:: End-to-end verification suite on Windows for the unified `libscript.cmd package-as` kernel and OS
:: bakery contract across Linux, FreeBSD, illumos, ReactOS, Unikernels, and RTOS, including 2x idempotency.
::
:: ## Usage
:: tests\test_package_as_kernels.cmd

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

if /I "%~1"=="--help" (
    echo Usage: %~nx0
    exit /b 0
)
if /I "%~1"=="-h" (
    echo Usage: %~nx0
    exit /b 0
)

set "TEST_WORK=%TEMP%\libscript_pkg_kernels_%RANDOM%"
if not exist "!TEST_WORK!" mkdir "!TEST_WORK!"

for %%T in (linux-distro linux-kernel freebsd-distro illumos-distro reactos-distro unikernel unikernel-distro rtos-distro firmware-bin direct-kernel qcow2) do (
    echo [TEST]     Help check: package-as %%T...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as %%T --help >nul || goto :fail
)

set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=illumos/minimal-server" "--export=!TEST_WORK!\illumos-os.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=freebsd/freebsd-server-standard" "--export=!TEST_WORK!\freebsd-os.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=reactos/desktop-classic-i686" "--export=!TEST_WORK!\reactos-os.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=linux/linux-minimal-headless-musl" "--export=!TEST_WORK!\linux-os.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=linux/linux-kernel-gcc-tiny" "--export=!TEST_WORK!\linux-kernel.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=unikernel/osv-cloud-runtime" "--export=!TEST_WORK!\unikernel-os.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=rtos/zephyr-cortex-m3-mcuboot-signed" "--export=!TEST_WORK!\zephyr-rtos.json" >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" config os "--profile=rtos/freertos-riscv64-static-safety" "--export=!TEST_WORK!\freertos-rtos.json" >nul || goto :fail

set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as illumos-distro --profile "!TEST_WORK!\illumos-os.json" --format qcow2 --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as freebsd-distro --profile "!TEST_WORK!\freebsd-os.json" --format qcow2 --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as reactos-distro --profile "!TEST_WORK!\reactos-os.json" --format qcow2 --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as linux-distro --profile "!TEST_WORK!\linux-os.json" --format qcow2 --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as linux-kernel --profile "!TEST_WORK!\linux-kernel.json" --format direct-kernel --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as unikernel-distro --profile "!TEST_WORK!\unikernel-os.json" --format elf --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as rtos-distro --profile "!TEST_WORK!\zephyr-rtos.json" --format firmware-bin --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as rtos-distro --profile "!TEST_WORK!\freertos-rtos.json" --format firmware-elf --dry-run >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as qcow2 --profile "!TEST_WORK!\linux-os.json" --dry-run >nul || goto :fail

set "UK_OUT=!TEST_WORK!\out-osv.unikernel.elf"
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as unikernel-distro --profile "!TEST_WORK!\unikernel-os.json" --format elf --output "!UK_OUT!" --allow-stub >nul || goto :fail
set "STACK=" & call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" package-as unikernel-distro --profile "!TEST_WORK!\unikernel-os.json" --format elf --output "!UK_OUT!" --allow-stub | findstr /C:"[SKIP]" >nul || goto :fail

rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [PASS] All unified kernel package-as syntax and 2x idempotency tests succeeded.
exit /b 0

:: ## fail
:: Cleans up temporary directory and exits non-zero on assertion failure.
:fail
rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [FAIL] Unified kernel package-as test suite failed. >&2
exit /b 1
