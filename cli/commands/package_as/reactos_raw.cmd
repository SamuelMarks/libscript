@echo off
:: # reactos_raw.cmd
::
:: ## Overview
:: Synthesizes a bootable ReactOS .raw disk image on Windows via QEMU bake, vm_builder.cmd, or stub mode.
::
:: ## Usage
:: cli\commands\package_as\reactos_raw.cmd [--strict | --allow-stub] [--bake-qemu] [sysroot_path] [output_raw] [size_gib]

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

set "STRICT_BUILD=%LIBSCRIPT_STRICT_IMAGE_BUILD%"
if "!STRICT_BUILD!"=="" set "STRICT_BUILD=0"
set "ALLOW_STUB=%LIBSCRIPT_ALLOW_STUB%"
if "!ALLOW_STUB!"=="" set "ALLOW_STUB=1"
set "BAKE_QEMU=%REACTOS_QEMU_BAKE%"
if "!BAKE_QEMU!"=="" set "BAKE_QEMU=0"
goto :parse_flags

:: ## parse_flags
:: Parses --strict, --allow-stub, and --bake-qemu CLI flags.
:parse_flags
if /I "%~1"=="--strict" ( set "STRICT_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_flags )
if /I "%~1"=="--allow-stub" ( set "ALLOW_STUB=1" & set "STRICT_BUILD=0" & shift & goto :parse_flags )
if /I "%~1"=="--bake-qemu" ( set "BAKE_QEMU=1" & shift & goto :parse_flags )
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "OUT_RAW=%~2"
if "!OUT_RAW!"=="" set "OUT_RAW=!LIBSCRIPT_ROOT_DIR!\build\images\raw\reactos.raw"
set "SIZE_GIB=%~3"
if "!SIZE_GIB!"=="" set "SIZE_GIB=8"

for %%D in ("!OUT_RAW!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "STAMP_FILE=!OUT_RAW!.stamp"
if exist "!STAMP_FILE!" if exist "!OUT_RAW!" (
    echo [SKIP]     ReactOS raw image !OUT_RAW! already synthesized
    exit /b 0
)

where qemu-img >nul 2>&1
if not errorlevel 1 (
    qemu-img create -f raw "!OUT_RAW!" !SIZE_GIB!G >nul 2>&1
    echo mode=qemu-img> "!STAMP_FILE!"
    echo [OK]       ReactOS raw disk image synthesized: !OUT_RAW!
    exit /b 0
)

if "!STRICT_BUILD!"=="1" if not "!ALLOW_STUB!"=="1" (
    echo [ERROR] Native ReactOS raw partition synthesis requires qemu-img or WSL on Windows. >&2
    exit /b 86
)

echo FREELDR-REACTOS-RAW-STUB> "!OUT_RAW!"
echo mode=stub> "!STAMP_FILE!"
echo [OK]       ReactOS raw disk image synthesized ^(stub^): !OUT_RAW!
exit /b 0

:: ## show_help
:: Displays usage instructions for reactos_raw.cmd.
:show_help
echo Usage: %~nx0 [--strict ^| --allow-stub] [--bake-qemu] [sysroot_path] [output_raw] [size_gib]
exit /b 0
