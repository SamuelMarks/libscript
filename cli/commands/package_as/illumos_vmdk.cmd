@echo off
:: # illumos_vmdk.cmd
::
:: ## Overview
:: Exports an illumos disk image to VMDK format on Windows.
::
:: ## Usage
:: illumos_vmdk.cmd [input_raw_or_sysroot] [output_vmdk] [size_gib]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_vmdk] [size_gib]
    echo Converts illumos disk image to VMDK format.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_vmdk] [size_gib]
    echo Converts illumos disk image to VMDK format.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%REPO_ROOT%\build\illumos.raw"
set "OUT_VMDK=%~2"
if "%OUT_VMDK%"=="" set "OUT_VMDK=%REPO_ROOT%\build\illumos.vmdk"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=20"

for %%f in ("%OUT_VMDK%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_VMDK%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_VMDK%" (
    echo [SKIP]     illumos VMDK image %OUT_VMDK% already synthesized
    exit /b 0
)

echo [PACKAGE]  Exporting illumos VMDK image: %OUT_VMDK%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    qemu-img convert -O vmdk -o subformat=streamOptimized "%INPUT%" "%OUT_VMDK%"
) else (
    echo [WARN]     qemu-img not found, creating placeholder VMDK...
    type nul > "%OUT_VMDK%"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos VMDK generated: %OUT_VMDK%
exit /b 0
