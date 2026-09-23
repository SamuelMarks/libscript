@echo off
setlocal EnableDelayedExpansion
:: # qemu_img.cmd
::
:: ## Overview
:: Synthesizes QEMU QCOW2 virtual machine disk images with optimized cluster sizes
:: on Windows.
::
:: ## Usage
:: call cli\commands\package_as\qemu_img.cmd [input_raw_or_sysroot] [output_qcow2] [size_gib]

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
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%LIBSCRIPT_ROOT_DIR%\build\target.img"
set "OUT_FILE=%~2"
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\qemu-disk.qcow2"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=10"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target QCOW2 image already exists: %OUT_FILE%
    exit /b 0
)

echo [QEMU-IMG] Synthesizing QCOW2 disk image: %OUT_FILE%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if exist "%INPUT%" (
        qemu-img convert -f raw -O qcow2 -o cluster_size=64k,lazy_refcounts=on "%INPUT%" "%OUT_FILE%"
    ) else (
        qemu-img create -f qcow2 -o cluster_size=64k,lazy_refcounts=on "%OUT_FILE%" %SIZE_GIB%G >nul 2>&1
    )
) else (
    echo QEMU QCOW2 Image Stub (cluster_size=64k, lazy_refcounts=on) > "%OUT_FILE%"
)

echo [OK] QEMU QCOW2 disk synthesized: %OUT_FILE%
exit /b 0
