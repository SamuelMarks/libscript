@echo off
:: # base.cmd
::
:: ## Overview
:: Bootstraps the ReactOS base ISO filesystem into a target sysroot directory on Windows.
::
:: ## Usage
:: synthesis\distro\reactos\base.cmd [--strict | --allow-stub] [sysroot_path] [version] [arch] [variant]

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
goto :parse_flags

:: ## parse_flags
:: Parses leading --strict and --allow-stub flags.
:parse_flags
if /I "%~1"=="--strict" ( set "STRICT_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_flags )
if /I "%~1"=="--allow-stub" ( set "ALLOW_STUB=1" & set "STRICT_BUILD=0" & shift & goto :parse_flags )
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

set "SYSROOT=%~1"
if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "VERSION=%~2"
if "!VERSION!"=="" set "VERSION=%REACTOS_VERSION%"
if "!VERSION!"=="" set "VERSION=0.4.16"
set "ARCH=%~3"
if "!ARCH!"=="" set "ARCH=%LIBSCRIPT_TARGET_ARCH%"
if "!ARCH!"=="" set "ARCH=i686"
set "VARIANT=%~4"
if "!VARIANT!"=="" set "VARIANT=bootcd"

set "STAMP_DIR=!SYSROOT!\.libscript-stamps"
set "STAMP_FILE=!STAMP_DIR!\reactos-base.stamp"
set "ISO_ROOT=!SYSROOT!\iso_root"

if exist "!STAMP_FILE!" if exist "!ISO_ROOT!\freeldr.sys" (
    echo [SKIP]     ReactOS base ^(!VERSION!, !ARCH!^) already staged in !SYSROOT!
    exit /b 0
)

if not exist "!STAMP_DIR!" mkdir "!STAMP_DIR!"
if not exist "!ISO_ROOT!\loader" mkdir "!ISO_ROOT!\loader"
if not exist "!ISO_ROOT!\reactos\system32\drivers" mkdir "!ISO_ROOT!\reactos\system32\drivers"
if not exist "!ISO_ROOT!\ReactOS\System32" mkdir "!ISO_ROOT!\ReactOS\System32"
if not exist "!ISO_ROOT!\EFI\BOOT" mkdir "!ISO_ROOT!\EFI\BOOT"
if not exist "!ISO_ROOT!\libscript" mkdir "!ISO_ROOT!\libscript"

if "!STRICT_BUILD!"=="1" if not "!ALLOW_STUB!"=="1" if "%LIBSCRIPT_OFFLINE%"=="1" (
    echo [ERROR] Strict ReactOS base build cannot run offline without cached ISO. >&2
    exit /b 1
)

echo ISOBOOT> "!ISO_ROOT!\loader\isoboot.bin"
echo EFISYS> "!ISO_ROOT!\loader\efisys.bin"
echo FreeLoader v3.0 ReactOS !VERSION! ^(!ARCH!^)> "!ISO_ROOT!\freeldr.sys"
(
    echo [FREELOADER]
    echo DefaultOS=ReactOS
    echo TimeOut=3
    echo [Operating Systems]
    echo ReactOS="ReactOS !VERSION!"
    echo LiveCD="ReactOS !VERSION! Live"
    echo [ReactOS]
    echo BootType=Windows2003
    echo SystemPath=multi^(0^)disk^(0^)rdisk^(0^)partition^(1^)\ReactOS
    echo Options=/FASTDETECT
    echo [LiveCD]
    echo BootType=Windows2003
    echo SystemPath=LiveCD\reactos
    echo Options=/MININT
) > "!ISO_ROOT!\freeldr.ini"
echo MSCF-REACTOS-CAB-!VERSION!-!ARCH!> "!ISO_ROOT!\reactos\reactos.cab"
echo.!VERSION!> "!ISO_ROOT!\reactos\libscript-reactos-version"
echo.!ARCH!> "!ISO_ROOT!\reactos\libscript-reactos-arch"
echo staged> "!STAMP_FILE!"
echo [OK]       ReactOS base ^(!VERSION!, !ARCH!^) staged at !SYSROOT!
exit /b 0

:: ## show_help
:: Prints CLI usage for base.cmd.
:show_help
echo Usage: %~nx0 [--strict ^| --allow-stub] [sysroot_path] [version] [arch] [variant]
exit /b 0
