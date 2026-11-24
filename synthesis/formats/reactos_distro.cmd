@echo off
:: # reactos_distro.cmd
::
:: ## Overview
:: Unified CLI entrypoint to synthesize and package a ReactOS distribution profile on Windows.
::
:: ## Usage
:: synthesis\formats\reactos_distro.cmd [--format <iso|qcow2|box|raw|vhd|vmdk>] [--profile <path>] [--output <path>] [--dry-run] [--allow-stub] [--strict]

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

set "FORMAT=iso"
set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\desktop-classic-i686.json"
set "OUTPUT="
set "SIZE_GIB=8"
set "SYSROOT="
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
goto :parse_args

:: ## parse_args
:: Parses CLI options for reactos_distro.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_RA=%~1"
if /I "!_RA!"=="--help" goto :show_help
if /I "!_RA!"=="-h" goto :show_help
if /I "!_RA!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_RA!"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_RA:~0,9!"=="--format=" ( set "FORMAT=!_RA:~9!" & shift & goto :parse_args )
if /I "!_RA!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "!_RA!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "!_RA:~0,10!"=="--profile=" ( set "PROFILE=!_RA:~10!" & shift & goto :parse_args )
if /I "!_RA!"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_RA!"=="--out" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_RA!"=="-o" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_RA:~0,9!"=="--output=" ( set "OUTPUT=!_RA:~9!" & shift & goto :parse_args )
if /I "!_RA:~0,6!"=="--out=" ( set "OUTPUT=!_RA:~6!" & shift & goto :parse_args )
if /I "!_RA!"=="--size" ( set "SIZE_GIB=%~2" & shift & shift & goto :parse_args )
if /I "!_RA:~0,7!"=="--size=" ( set "SIZE_GIB=!_RA:~7!" & shift & goto :parse_args )
if /I "!_RA!"=="--sysroot" ( set "SYSROOT=%~2" & shift & shift & goto :parse_args )
if /I "!_RA:~0,10!"=="--sysroot=" ( set "SYSROOT=!_RA:~10!" & shift & goto :parse_args )
if /I "!_RA!"=="--from-source" ( set "REACTOS_BUILD_FROM_SOURCE=1" & shift & goto :parse_args )
if /I "!_RA!"=="--bake-qemu" ( set "REACTOS_QEMU_BAKE=1" & shift & goto :parse_args )
if /I "!_RA!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /I "!_RA!"=="--strict" ( set "LIBSCRIPT_STRICT_IMAGE_BUILD=1" & set "LIBSCRIPT_ALLOW_STUB=0" & shift & goto :parse_args )
if /I "!_RA!"=="--allow-stub" ( set "LIBSCRIPT_ALLOW_STUB=1" & set "LIBSCRIPT_STRICT_IMAGE_BUILD=0" & shift & goto :parse_args )
if /I "!_RA!"=="--offline" ( set "LIBSCRIPT_OFFLINE=1" & shift & goto :parse_args )
echo [ERROR] Unknown argument: !_RA! >&2
exit /b 1

:: ## args_done
:: Validates profile, checks idempotency stamp, and dispatches ReactOS packaging.
:args_done
set "_RP=!PROFILE:/=\!"
if not exist "!_RP!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_RP!.json" set "_RP=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_RP!.json"
if not exist "!_RP!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\!_RP!.json" set "_RP=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\!_RP!.json"
set "PROFILE=!_RP!"
if not exist "!PROFILE!" (
    echo [ERROR] ReactOS profile not found: !PROFILE! >&2
    exit /b 1
)

for %%F in ("!PROFILE!") do set "PNAME=%%~nF"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\reactos-sysroot-!PNAME!"

if /I "!FORMAT!"=="raw-img" set "FORMAT=raw"
if /I "!FORMAT!"=="vagrant-box" set "FORMAT=box"
if /I "!FORMAT!"=="live-iso" set "FORMAT=iso"

if /I "!FORMAT!"=="iso" if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\iso\reactos-!PNAME!.iso"
if /I "!FORMAT!"=="raw" if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\raw\reactos-!PNAME!.raw"
if /I "!FORMAT!"=="qcow2" if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\qemu\reactos-!PNAME!.qcow2"
if /I "!FORMAT!"=="vhd" if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\hyperv\reactos-!PNAME!.vhd"
if /I "!FORMAT!"=="vmdk" if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\vmware\reactos-!PNAME!.vmdk"
if /I "!FORMAT!"=="box" if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\vagrant\reactos-!PNAME!.box"
if "!OUTPUT!"=="" (
    echo [ERROR] Unsupported ReactOS packaging format: !FORMAT! >&2
    exit /b 1
)

if "!DRY_RUN!"=="1" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\cli\commands\config\config.cmd" os "--validate=!PROFILE!"
    if errorlevel 1 exit /b !ERRORLEVEL!
    echo [DRYRUN]   ReactOS distribution plan verified ^(format=!FORMAT!^) -^> !OUTPUT!
    exit /b 0
)

set "STAMP_FILE=!OUTPUT!.distro.stamp"
if exist "!STAMP_FILE!" if exist "!OUTPUT!" (
    findstr /I /C:"format=!FORMAT!" "!STAMP_FILE!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP]     ReactOS distribution artifact already synthesized: !OUTPUT!
        exit /b 0
    )
)

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\reactos\assemble.cmd" "!PROFILE!" "!SYSROOT!"
if errorlevel 1 exit /b !errorlevel!

if /I "!FORMAT!"=="iso" (
    set "STACK=" & call "!SCRIPT_DIR!\reactos_iso.cmd" "!SYSROOT!" "!OUTPUT!" || exit /b 1
)
if /I "!FORMAT!"=="raw" (
    set "STACK=" & call "!SCRIPT_DIR!\reactos_raw.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!" || exit /b 1
)
if /I "!FORMAT!"=="qcow2" (
    set "STACK=" & call "!SCRIPT_DIR!\reactos_qcow2.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!" || exit /b 1
)
if /I "!FORMAT!"=="vhd" (
    set "STACK=" & call "!SCRIPT_DIR!\reactos_vhd.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!" || exit /b 1
)
if /I "!FORMAT!"=="vmdk" (
    set "STACK=" & call "!SCRIPT_DIR!\reactos_vmdk.cmd" "!SYSROOT!" "!OUTPUT!" "!SIZE_GIB!" || exit /b 1
)
if /I "!FORMAT!"=="box" (
    set "_QTMP=!OUTPUT!.qcow2.tmp"
    set "STACK=" & call "!SCRIPT_DIR!\reactos_qcow2.cmd" "!SYSROOT!" "!_QTMP!" "!SIZE_GIB!" || exit /b 1
    set "STACK=" & call "!SCRIPT_DIR!\reactos_vagrant_box.cmd" "!_QTMP!" "!OUTPUT!" "qemu" || exit /b 1
    del /f /q "!_QTMP!" "!_QTMP!.stamp" >nul 2>&1
)

(
    echo format=!FORMAT!
    echo profile=!PROFILE!
) > "!STAMP_FILE!"
echo [OK]       ReactOS distribution packaged as !FORMAT!: !OUTPUT!
exit /b 0

:: ## show_help
:: Displays usage instructions for reactos_distro.cmd.
:show_help
echo Usage: %~nx0 [--format ^<iso^|qcow2^|box^|raw^|vhd^|vmdk^>] [--profile ^<path^|preset^>] [--output ^<path^>] [--dry-run] [--allow-stub]
exit /b 0
