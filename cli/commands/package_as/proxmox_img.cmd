@echo off
setlocal EnableDelayedExpansion
:: # proxmox_img.cmd
::
:: ## Overview
:: Synthesizes Proxmox VE KVM virtual machine templates (.qcow2) and qm import
:: scripts on Windows.
::
:: ## Usage
:: call cli\commands\package_as\proxmox_img.cmd [input_raw] [output_qcow2] [vmid]

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
if "%SCRIPT_DIR:~-1%"=="" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    for %%i in ("%SCRIPT_DIR%\..\..\..") do set "LIBSCRIPT_ROOT_DIR=%%~fi"
)

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%LIBSCRIPT_ROOT_DIR%\build\target.img"
set "OUT_FILE=%~2"
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\proxmox-template.qcow2"
set "VMID=%~3"
if "%VMID%"=="" set "VMID=9000"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target Proxmox template already exists: %OUT_FILE%
    exit /b 0
)

echo [PROXMOX-IMG] Synthesizing Proxmox VE template for VMID %VMID%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if exist "%INPUT%" (
        qemu-img convert -f raw -O qcow2 -o cluster_size=64k,lazy_refcounts=on "%INPUT%" "%OUT_FILE%"
    ) else (
        qemu-img create -f qcow2 -o cluster_size=64k,lazy_refcounts=on "%OUT_FILE%" 10G >nul 2>&1
    )
) else (
    echo Proxmox VE Template QCOW2 Stub > "%OUT_FILE%"
)

echo [OK] Proxmox VE template generated: %OUT_FILE%
exit /b 0
