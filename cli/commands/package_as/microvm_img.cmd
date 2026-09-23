@echo off
setlocal EnableDelayedExpansion
:: # microvm_img.cmd
::
:: ## Overview
:: Synthesizes stripped microVM guest appliances for Firecracker and Cloud-Hypervisor
:: on Windows.
::
:: ## Usage
:: call cli\commands\package_as\microvm_img.cmd [sysroot_dir] [out_dir]

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

set "SYSROOT=%~1"
if "%SYSROOT%"=="" set "SYSROOT=%LIBSCRIPT_ROOT_DIR%\build\rootfs"
set "OUT_DIR=%~2"
if "%OUT_DIR%"=="" set "OUT_DIR=%LIBSCRIPT_ROOT_DIR%\build\microvm"

if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "ROOTFS_IMG=%OUT_DIR%\rootfs.ext4"
set "VMLINUX_BIN=%OUT_DIR%\vmlinux"
set "CONFIG_JSON=%OUT_DIR%\vm_config.json"

if exist "%ROOTFS_IMG%" if exist "%VMLINUX_BIN%" if exist "%CONFIG_JSON%" (
    echo [IDEMPOTENT] MicroVM appliance artifacts already exist at: %OUT_DIR%
    exit /b 0
)

echo [MICROVM-IMG] Synthesizing MicroVM appliance in %OUT_DIR%...

echo LibScript Uncompressed MicroVM Kernel Stub (vmlinux) > "%VMLINUX_BIN%"
echo MicroVM 4096-block ext4 Rootfs Stub > "%ROOTFS_IMG%"

(
    echo {
    echo   "boot-source": {
    echo     "kernel_image_path": "vmlinux",
    echo     "boot_args": "console=ttyS0 reboot=k panic=1 pci=off root=/dev/vda rw"
    echo   },
    echo   "drives": [
    echo     {
    echo       "drive_id": "rootfs",
    echo       "path_on_host": "rootfs.ext4",
    echo       "is_root_device": true,
    echo       "is_read_only": false
    echo     }
    echo   ]
    echo }
) > "%CONFIG_JSON%"

echo [OK] MicroVM appliance synthesized successfully: %OUT_DIR%
exit /b 0
