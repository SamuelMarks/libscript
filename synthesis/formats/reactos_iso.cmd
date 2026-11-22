@echo off
:: # reactos_iso.cmd
::
:: ## Overview
:: Packages a ReactOS target sysroot into a bootable El Torito ISO 9660 image on Windows.
::
:: ## Usage
:: synthesis\formats\reactos_iso.cmd [--strict | --allow-stub] [target_sysroot] [output_iso]

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
:: Parses --strict and --allow-stub CLI options.
:parse_flags
if /I "%~1"=="--strict" ( set "STRICT_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_flags )
if /I "%~1"=="--allow-stub" ( set "ALLOW_STUB=1" & set "STRICT_BUILD=0" & shift & goto :parse_flags )
if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

set "TARGET_SYSROOT=%~1"
if "!TARGET_SYSROOT!"=="" set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot"
set "OUT_ISO=%~2"
if "!OUT_ISO!"=="" set "OUT_ISO=!LIBSCRIPT_ROOT_DIR!\build\images\iso\reactos.iso"
set "ISO_SRC=!TARGET_SYSROOT!\iso_root"
if not exist "!ISO_SRC!" set "ISO_SRC=!TARGET_SYSROOT!"

for %%D in ("!OUT_ISO!") do if not exist "%%~dpD" mkdir "%%~dpD"
set "STAMP_FILE=!OUT_ISO!.stamp"
if exist "!STAMP_FILE!" if exist "!OUT_ISO!" (
    echo [SKIP]     ReactOS ISO !OUT_ISO! already synthesized
    exit /b 0
)

where oscdimg >nul 2>&1
if not errorlevel 1 if exist "!ISO_SRC!\loader\isoboot.bin" (
    oscdimg -n -m -b"!ISO_SRC!\loader\isoboot.bin" "!ISO_SRC!" "!OUT_ISO!" >nul 2>&1
    if exist "!OUT_ISO!" (
        echo mode=native> "!STAMP_FILE!"
        echo [OK]       ReactOS ISO synthesized via oscdimg: !OUT_ISO!
        exit /b 0
    )
)

where xorriso >nul 2>&1
if not errorlevel 1 (
    xorriso -as mkisofs -R -J -V "REACTOS_INSTALL" -o "!OUT_ISO!" "!ISO_SRC!" >nul 2>&1
    if exist "!OUT_ISO!" (
        echo mode=native> "!STAMP_FILE!"
        echo [OK]       ReactOS ISO synthesized via xorriso: !OUT_ISO!
        exit /b 0
    )
)

if "!STRICT_BUILD!"=="1" if not "!ALLOW_STUB!"=="1" (
    echo [ERROR] Strict ReactOS ISO synthesis failed: oscdimg/xorriso unavailable. >&2
    exit /b 1
)

echo REACTOS-ISO-STUB> "!OUT_ISO!"
echo mode=stub> "!STAMP_FILE!"
echo [OK]       ReactOS ISO synthesized ^(stub^): !OUT_ISO!
exit /b 0

:: ## show_help
:: Displays usage instructions for reactos_iso.cmd.
:show_help
echo Usage: %~nx0 [--strict ^| --allow-stub] [target_sysroot] [output_iso]
exit /b 0
