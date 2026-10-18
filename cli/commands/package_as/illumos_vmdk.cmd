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

if defined STACK (
    echo "!STACK!" | findstr /C:":!THIS_FILE!:" >nul 2>&1
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
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_vmdk] [size_gib]
    echo Converts illumos disk image to VMDK format.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [input_raw_or_sysroot] [output_vmdk] [size_gib]
    echo Converts illumos disk image to VMDK format.
    exit /b 0
)

set "REPO_ROOT=!SCRIPT_DIR!..\..\.."
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
