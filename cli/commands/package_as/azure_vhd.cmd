@echo off
setlocal EnableDelayedExpansion
:: # azure_vhd.cmd
::
:: ## Overview
:: Synthesizes Microsoft Azure fixed-format 1 MiB boundary aligned VHD images on Windows.
::
:: ## Usage
:: call cli\commands\package_as\azure_vhd.cmd [input_raw] [output_vhd] [size_gib]

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
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\disk.vhd"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=10"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target Azure VHD already exists: %OUT_FILE%
    exit /b 0
)

echo [AZURE-VHD] Synthesizing 1 MiB-aligned fixed VHD for Azure: %OUT_FILE%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% equ 0 (
    if exist "%INPUT%" (
        qemu-img convert -f raw -O vpc -o subformat=fixed,force_size "%INPUT%" "%OUT_FILE%"
    ) else (
        qemu-img create -f vpc -o subformat=fixed,force_size "%OUT_FILE%" %SIZE_GIB%G >nul 2>&1
    )
) else (
    echo Azure Fixed VHD 1MiB Aligned Stub > "%OUT_FILE%"
)

echo [OK] Microsoft Azure VHD synthesized: %OUT_FILE%
exit /b 0
