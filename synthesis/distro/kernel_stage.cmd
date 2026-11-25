@echo off
:: # setup.cmd
:: ## Overview
:: Windows Batch companion for Linux kernel configuration and initramfs synthesis. Implements Option A Win32 Hard-Fail boundary proforma.
:: ## Usage
:: synthesis\distro\kernel_stage.cmd [install|clean|status]

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



IF /I "%LIBSCRIPT_TARGET_OS%"=="zephyr" (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\zephyr\build_firmware.cmd"
    exit /b !ERRORLEVEL!
)
IF /I "%LIBSCRIPT_TARGET_OS%"=="rtos-zephyr" (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\zephyr\build_firmware.cmd"
    exit /b !ERRORLEVEL!
)
IF /I "%LIBSCRIPT_TARGET_OS%"=="freertos" (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\freertos\build_firmware.cmd"
    exit /b !ERRORLEVEL!
)
IF /I "%LIBSCRIPT_TARGET_OS%"=="rtos-freertos" (
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\freertos\build_firmware.cmd"
    exit /b !ERRORLEVEL!
)
IF /I "%LIBSCRIPT_TARGET_OS%"=="freedos" (
    set "ACTION=install"
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\freedos\setup.cmd"
    exit /b !ERRORLEVEL!
)
IF /I "%LIBSCRIPT_TARGET_OS%"=="msdos" (
    set "ACTION=install"
    set "STACK="
    call "%LIBSCRIPT_ROOT_DIR%\_lib\kernel\msdos\setup.cmd"
    exit /b !ERRORLEVEL!
)

IF "%~1"=="status" (
    echo === LFS Kernel Status ^(Win32^) ===
    echo Kernel compilation and module generation execute inside Linux container or VM builder.
    goto end
)

:: Option A Win32 Hard-Fail Boundary Proforma
echo [ERROR] Native Linux kernel compilation and initramfs synthesis is unavailable on Win32. >&2
echo [ERROR] Please execute via container or VM builder: vm_builder.cmd >&2
exit /b 86

:: ## end
:: Exits the batch script cleanly and returns control to the caller.
:end
exit /b 0
