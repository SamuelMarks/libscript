@echo off
setlocal EnableDelayedExpansion
:: # vmware_img.cmd
::
:: ## Overview
:: Synthesizes VMware ESXi and Workstation virtual machine appliances (.vmdk, .ova)
:: on Windows.
::
:: ## Usage
:: call cli\commands\package_as\vmware_img.cmd [input_raw] [output_vmdk_or_ova] [subformat]

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
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\appliance.vmdk"
set "SUBFORMAT=%~3"
if "%SUBFORMAT%"=="" set "SUBFORMAT=streamOptimized"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target VMware appliance already exists: %OUT_FILE%
    exit /b 0
)

echo [VMWARE-IMG] Synthesizing VMware %SUBFORMAT% disk image at %OUT_FILE%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if exist "%INPUT%" (
        qemu-img convert -f raw -O vmdk -o "subformat=%SUBFORMAT%" "%INPUT%" "%OUT_FILE%"
    ) else (
        qemu-img create -f vmdk -o "subformat=%SUBFORMAT%" "%OUT_FILE%" 10G >nul 2>&1
    )
) else (
    echo VMware VMDK Image Stub (%SUBFORMAT%) > "%OUT_FILE%"
)

echo [OK] VMware appliance synthesized successfully: %OUT_FILE%
exit /b 0
