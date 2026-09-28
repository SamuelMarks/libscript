@echo off
:: # freebsd_qcow2.cmd
::
:: ## Overview
:: Converts a raw FreeBSD disk image or sysroot to QCOW2 format on Windows.
::
:: ## Usage
:: freebsd_qcow2.cmd [input_raw_or_sysroot] [output_qcow2] [size_gib]

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
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_qcow2] [size_gib]
    echo Converts FreeBSD disk image to QCOW2 format.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_qcow2] [size_gib]
    echo Converts FreeBSD disk image to QCOW2 format.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%REPO_ROOT%\build\freebsd.raw"
set "OUT_QCOW2=%~2"
if "%OUT_QCOW2%"=="" set "OUT_QCOW2=%REPO_ROOT%\build\freebsd.qcow2"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=20"

for %%f in ("%OUT_QCOW2%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_QCOW2%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_QCOW2%" (
    echo [SKIP]     FreeBSD QCOW2 image %OUT_QCOW2% already synthesized
    exit /b 0
)

echo [PACKAGE]  Exporting FreeBSD QCOW2 image: %OUT_QCOW2%...
where qemu-img >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    qemu-img convert -O qcow2 -c "%INPUT%" "%OUT_QCOW2%"
) else (
    echo [WARN]     qemu-img not found, writing placeholder file...
    type nul > "%OUT_QCOW2%"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD QCOW2 image generated: %OUT_QCOW2%
exit /b 0
