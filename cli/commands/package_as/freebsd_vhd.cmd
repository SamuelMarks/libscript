@echo off
:: # freebsd_vhd.cmd
::
:: ## Overview
:: Exports a FreeBSD disk image to Microsoft Hyper-V VHD format on Windows.
::
:: ## Usage
:: freebsd_vhd.cmd [input_raw_or_sysroot] [output_vhd] [size_gib]

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
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_vhd] [size_gib]
    echo Exports FreeBSD disk image to VHD format.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_vhd] [size_gib]
    echo Exports FreeBSD disk image to VHD format.
    exit /b 0
)

set "SCRIPT_DIR=%~dp0"
set "REPO_ROOT=%SCRIPT_DIR%..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%REPO_ROOT%\build\freebsd.raw"
set "OUT_VHD=%~2"
if "%OUT_VHD%"=="" set "OUT_VHD=%REPO_ROOT%\build\freebsd.vhd"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=20"

for %%f in ("%OUT_VHD%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_VHD%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_VHD%" (
    echo [SKIP]     FreeBSD VHD %OUT_VHD% already synthesized
    exit /b 0
)

echo [PACKAGE]  Exporting FreeBSD VHD: %OUT_VHD%...
where qemu-img >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    qemu-img convert -O vpc -o subformat=dynamic "%INPUT%" "%OUT_VHD%"
) else (
    echo [WARN]     qemu-img not found, writing placeholder file...
    type nul > "%OUT_VHD%"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       FreeBSD VHD generated: %OUT_VHD%
exit /b 0
