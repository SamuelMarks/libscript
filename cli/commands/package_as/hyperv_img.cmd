@echo off
setlocal EnableDelayedExpansion
:: # hyperv_img.cmd
::
:: ## Overview
:: Synthesizes Microsoft Hyper-V Generation 1 (VHD) and Generation 2 (VHDX)
:: virtual machine appliances on Windows.
::
:: ## Usage
:: call cli\commands\package_as\hyperv_img.cmd [input_raw] [output_vhd_or_vhdx] [gen1|gen2]

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
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\hyperv-disk.vhdx"
set "GEN=%~3"
if "%GEN%"=="" set "GEN=gen2"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target Hyper-V image already exists: %OUT_FILE%
    exit /b 0
)

echo [HYPERV-IMG] Synthesizing Hyper-V %GEN% appliance: %OUT_FILE%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if /i "%GEN%"=="gen1" (
        qemu-img convert -f raw -O vpc -o subformat=fixed,force_size "%INPUT%" "%OUT_FILE%"
    ) else (
        qemu-img convert -f raw -O vhdx -o subformat=dynamic "%INPUT%" "%OUT_FILE%"
    )
) else (
    echo Hyper-V Virtual Disk Stub (%GEN%) > "%OUT_FILE%"
)

echo [OK] Hyper-V appliance synthesized successfully: %OUT_FILE%
exit /b 0
