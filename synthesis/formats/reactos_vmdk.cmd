@echo off
:: # reactos_vmdk.cmd
::
:: ## Overview
:: Packages an assembled ReactOS sysroot into a VMware .vmdk virtual disk image on Windows.
::
:: ## Usage
:: synthesis\formats\reactos_vmdk.cmd [sysroot_path] [output_vmdk] [size_gib]

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

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "OUT_VMDK=%~2"
if "!OUT_VMDK!"=="" set "OUT_VMDK=!LIBSCRIPT_ROOT_DIR!\build\images\vmware\reactos.vmdk"
set "SIZE_GIB=%~3"
if "!SIZE_GIB!"=="" set "SIZE_GIB=8"
set "STAMP_FILE=!OUT_VMDK!.stamp"

if exist "!STAMP_FILE!" if exist "!OUT_VMDK!" (
    echo [SKIP]     ReactOS VMDK image !OUT_VMDK! already synthesized
    exit /b 0
)
for %%D in ("!OUT_VMDK!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "RAW_TMP=!OUT_VMDK!.raw.tmp"
set "STACK=" & call "!SCRIPT_DIR!\reactos_raw.cmd" --allow-stub "!SYSROOT!" "!RAW_TMP!" "!SIZE_GIB!"
where qemu-img >nul 2>&1
if not errorlevel 1 (
    qemu-img convert -f raw -O vmdk "!RAW_TMP!" "!OUT_VMDK!" >nul 2>&1
) else (
    copy /y "!RAW_TMP!" "!OUT_VMDK!" >nul 2>&1
)
del /f /q "!RAW_TMP!" "!RAW_TMP!.stamp" >nul 2>&1
echo synthesized> "!STAMP_FILE!"
echo [OK]       ReactOS VMDK image synthesized: !OUT_VMDK!
exit /b 0
