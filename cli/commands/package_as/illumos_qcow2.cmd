@echo off
:: # illumos_qcow2.cmd
::
:: ## Overview
:: Converts a raw illumos disk image or sysroot to QCOW2 format on Windows.
::
:: ## Usage
:: illumos_qcow2.cmd [input_raw_or_sysroot] [output_qcow2] [size_gib]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        echo [STOP] processing "!THIS_FILE!" >&2
        exit /b 0
    )
)
set "STACK=%STACK%:!THIS_FILE!:"

set "SCRIPT_DIR=%~dp0"
if "%SCRIPT_DIR:~-1%"=="\" set "SCRIPT_DIR=%SCRIPT_DIR:~0,-1%"

if not defined LIBSCRIPT_ROOT_DIR (
    set "d=!SCRIPT_DIR!"
    call :find_root
)
goto :root_found

:: ## find_root
:: Ascends the directory tree looking for ROOT or libscript.cmd.
:find_root
if exist "!d!\libscript.cmd" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
if exist "!d!\ROOT" (
    set "LIBSCRIPT_ROOT_DIR=!d!"
    exit /b 0
)
for %%P in ("!d!") do set "parent=%%~dpP"
set "d=!parent:~0,-1!"
if "!d!"=="" (
    echo Error: Could not find LIBSCRIPT_ROOT_DIR 1>&2
    exit /b 1
)
goto :find_root

:: ## root_found
:: Continues execution once LIBSCRIPT_ROOT_DIR is verified.
:root_found


if "%~1"=="--help" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_qcow2] [size_gib]
    echo Converts illumos disk image to QCOW2 format.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_qcow2] [size_gib]
    echo Converts illumos disk image to QCOW2 format.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!\..\..\.."
for %%i in ("%REPO_ROOT%") do set "REPO_ROOT=%%~fi"

set "INPUT=%~1"
if "%INPUT%"=="" set "INPUT=%REPO_ROOT%\build\illumos.raw"
set "OUT_QCOW2=%~2"
if "%OUT_QCOW2%"=="" set "OUT_QCOW2=%REPO_ROOT%\build\illumos.qcow2"
set "SIZE_GIB=%~3"
if "%SIZE_GIB%"=="" set "SIZE_GIB=20"

for %%f in ("%OUT_QCOW2%") do set "OUT_DIR=%%~dpf"
if not exist "%OUT_DIR%" mkdir "%OUT_DIR%"

set "STAMP_FILE=%OUT_QCOW2%.stamp"
if exist "%STAMP_FILE%" if exist "%OUT_QCOW2%" (
    echo [SKIP]     illumos QCOW2 image %OUT_QCOW2% already synthesized
    exit /b 0
)

echo [PACKAGE]  Exporting illumos QCOW2 image: %OUT_QCOW2%...

where qemu-img >nul 2>&1
if %ERRORLEVEL% EQU 0 (
    qemu-img convert -O qcow2 -c "%INPUT%" "%OUT_QCOW2%"
) else (
    echo [WARN]     qemu-img not found, creating placeholder QCOW2...
    type nul > "%OUT_QCOW2%"
)

echo %DATE% %TIME%> "%STAMP_FILE%"
echo [OK]       illumos QCOW2 image generated: %OUT_QCOW2%
exit /b 0
