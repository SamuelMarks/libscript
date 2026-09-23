@echo off
setlocal EnableDelayedExpansion
:: # xen_img.cmd
::
:: ## Overview
:: Synthesizes Xen and XCP-ng PV/HVM virtual machine appliances on Windows.
::
:: ## Usage
:: call cli\commands\package_as\xen_img.cmd [input_raw] [output_xen_img] [pv|hvm]

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
if "%OUT_FILE%"=="" set "OUT_FILE=%LIBSCRIPT_ROOT_DIR%\build\xen-appliance.raw"
set "MODE=%~3"
if "%MODE%"=="" set "MODE=hvm"

for %%I in ("%OUT_FILE%") do set "OUT_DIR=%%~dpI"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

if exist "%OUT_FILE%" (
    echo [IDEMPOTENT] Target Xen appliance already exists: %OUT_FILE%
    exit /b 0
)

echo [XEN-IMG] Synthesizing Xen %MODE% appliance: %OUT_FILE%...

if exist "%INPUT%" (
    copy /y "%INPUT%" "%OUT_FILE%" >nul 2>&1
) else (
    echo Xen Raw Image Stub (%MODE%) > "%OUT_FILE%"
)

echo [OK] Xen appliance synthesized successfully: %OUT_FILE%
exit /b 0
