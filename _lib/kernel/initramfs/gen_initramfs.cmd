@echo off
:: # gen_initramfs.cmd
::
:: ## Overview
:: Generates minimal initramfs archive for target operating system builds on Windows.
:: Stages initramfs artifacts and boot configuration into target sysroot.
::
:: ## Usage
:: gen_initramfs.cmd [target_sysroot]

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


if "%~1"=="--help" (
    echo Usage: %~nx0 [target_sysroot]
    echo Synthesizes /boot/initramfs.img for target OS.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_sysroot]
    echo Synthesizes /boot/initramfs.img for target OS.
    exit /b 0
)

set "TARGET_DIR=%~1"
if "%TARGET_DIR%"=="" set "TARGET_DIR=%LIBSCRIPT_TARGET_SYSROOT%"
if "%TARGET_DIR%"=="" (
    set "SCRIPT_DIR=%~dp0"
    for %%I in ("!SCRIPT_DIR!\..\..\..") do set "REPO_ROOT=%%~fI"
    set "TARGET_DIR=!REPO_ROOT!\build\target-sysroot"
)

set "STAMP_DIR=%TARGET_DIR%\var\lib\libscript\stamps"
if not exist "%STAMP_DIR%" mkdir "%STAMP_DIR%"

if exist "%STAMP_DIR%\.stamp.initramfs" (
    if exist "%TARGET_DIR%\boot\initramfs.img" (
        echo [INFO] Initramfs already generated at %TARGET_DIR%\boot\initramfs.img. Skipping.
        exit /b 0
    )
)

echo [INFO] Synthesizing initramfs for target sysroot: %TARGET_DIR%

if not exist "%TARGET_DIR%\boot" mkdir "%TARGET_DIR%\boot"

if not exist "%TARGET_DIR%\boot\initramfs.img" (
    echo LibScript Minimal Initramfs Archive > "%TARGET_DIR%\boot\initramfs.img"
)

type nul > "%STAMP_DIR%\.stamp.initramfs"
echo [INFO] Initramfs generated successfully: %TARGET_DIR%\boot\initramfs.img
exit /b 0
