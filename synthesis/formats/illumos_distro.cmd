@echo off
:: # illumos_distro.cmd
:: ## Overview
:: Unified CLI entrypoint to package an illumos distribution profile into raw, qcow2, vagrant box, vhd, vmdk, iso, zfs-stream, or direct-kernel target formats on Windows.
:: ## Usage
:: illumos_distro.cmd [--format <qcow2|box|raw|vhd|vmdk|iso|zfs-stream|direct-kernel>] [--profile <profile_json>] [--output <path>] [--dry-run] [--allow-stub] [--strict]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

if defined STACK (
    echo "!STACK!" | findstr /I /C:":!THIS_FILE!:" >nul 2>&1
    if not errorlevel 1 (
        if "%LIBSCRIPT_DEBUG%"=="1" echo [STOP] processing "!THIS_FILE!" >&2
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

set "REPO_ROOT=!LIBSCRIPT_ROOT_DIR!"
set "FORMAT=qcow2"
set "PROFILE=!REPO_ROOT!\synthesis\profiles\illumos\minimal-server.json"
set "OUTPUT="
set "SYSROOT="
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
goto :parse_loop

:: ## parse_loop
:: Parses command-line arguments and populates configuration variables.
:parse_loop
if "%~1"=="" goto :parse_done
set "_IA=%~1"
if /I "!_IA!"=="--help" goto :show_help
if /I "!_IA!"=="-h" goto :show_help
if /I "!_IA!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA!"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA:~0,9!"=="--format=" ( set "FORMAT=!_IA:~9!" & shift & goto :parse_loop )
if /I "!_IA!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA:~0,10!"=="--profile=" ( set "PROFILE=!_IA:~10!" & shift & goto :parse_loop )
if /I "!_IA!"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA!"=="--out" ( set "OUTPUT=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA!"=="-o" ( set "OUTPUT=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA:~0,9!"=="--output=" ( set "OUTPUT=!_IA:~9!" & shift & goto :parse_loop )
if /I "!_IA:~0,6!"=="--out=" ( set "OUTPUT=!_IA:~6!" & shift & goto :parse_loop )
if /I "!_IA!"=="--sysroot" ( set "SYSROOT=%~2" & shift & shift & goto :parse_loop )
if /I "!_IA:~0,10!"=="--sysroot=" ( set "SYSROOT=!_IA:~10!" & shift & goto :parse_loop )
if /I "!_IA!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_loop )
if /I "!_IA!"=="--strict" ( set "LIBSCRIPT_STRICT_IMAGE_BUILD=1" & set "LIBSCRIPT_ALLOW_STUB=0" & shift & goto :parse_loop )
if /I "!_IA!"=="--allow-stub" ( set "LIBSCRIPT_ALLOW_STUB=1" & set "LIBSCRIPT_STRICT_IMAGE_BUILD=0" & shift & goto :parse_loop )
if /I "!_IA!"=="--offline" ( set "LIBSCRIPT_OFFLINE=1" & shift & goto :parse_loop )
echo [ERROR] Unknown argument: !_IA! >&2
exit /b 1

:: ## show_help
:: Displays usage instructions for illumos_distro.cmd.
:show_help
echo Usage: %~nx0 [--format ^<qcow2^|box^|raw^|vhd^|vmdk^|iso^|zfs-stream^|direct-kernel^>] [--profile ^<path^|preset^>] [--output ^<path^>] [--dry-run] [--allow-stub]
exit /b 0

:: ## parse_done
:: Validates profile, checks idempotency stamp, and dispatches illumos synthesis.
:parse_done
set "_IP=!PROFILE:/=\!"
if not exist "!_IP!" if exist "!REPO_ROOT!\synthesis\profiles\!_IP!.json" set "_IP=!REPO_ROOT!\synthesis\profiles\!_IP!.json"
if not exist "!_IP!" if exist "!REPO_ROOT!\synthesis\profiles\illumos\!_IP!.json" set "_IP=!REPO_ROOT!\synthesis\profiles\illumos\!_IP!.json"
set "PROFILE=!_IP!"
if not exist "!PROFILE!" (
    echo [ERROR] illumos profile not found: !PROFILE! >&2
    exit /b 1
)

if /I "!FORMAT!"=="raw-img" set "FORMAT=raw"
if /I "!FORMAT!"=="vagrant-box" set "FORMAT=box"
if /I "!FORMAT!"=="live-iso" set "FORMAT=iso"

if /I "!FORMAT!"=="raw" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\raw\illumos.raw"
if /I "!FORMAT!"=="qcow2" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\qemu\illumos.qcow2"
if /I "!FORMAT!"=="box" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\vagrant\illumos.box"
if /I "!FORMAT!"=="vhd" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\hyperv\illumos.vhd"
if /I "!FORMAT!"=="vmdk" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\vmware\illumos.vmdk"
if /I "!FORMAT!"=="iso" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\iso\illumos.iso"
if /I "!FORMAT!"=="zfs-stream" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\zfs\illumos.zfs.zst"
if /I "!FORMAT!"=="direct-kernel" if "!OUTPUT!"=="" set "OUTPUT=!REPO_ROOT!\build\images\direct-kernel\illumos"
if "!OUTPUT!"=="" (
    echo [ERROR] Unsupported packaging format: !FORMAT! >&2
    exit /b 1
)

if "!DRY_RUN!"=="1" (
    set "STACK="
    call "!REPO_ROOT!\cli\commands\config\config.cmd" os "--validate=!PROFILE!"
    if errorlevel 1 exit /b !ERRORLEVEL!
    echo [DRYRUN]   illumos distribution plan verified ^(format=!FORMAT!^) -^> !OUTPUT!
    exit /b 0
)

set "STAMP_FILE=!OUTPUT!.distro.stamp"
if exist "!STAMP_FILE!" if exist "!OUTPUT!" (
    findstr /I /C:"format=!FORMAT!" "!STAMP_FILE!" >nul 2>&1
    if not errorlevel 1 (
        echo [SKIP]     illumos distribution artifact already synthesized: !OUTPUT!
        exit /b 0
    )
)

for %%F in ("!PROFILE!") do set "PNAME=%%~nF"
if "!SYSROOT!"=="" set "SYSROOT=!REPO_ROOT!\build\illumos-sysroot-!PNAME!"
echo [DISTRO]   Synthesizing illumos sysroot from !PROFILE!...
set "STACK="
call "!REPO_ROOT!\synthesis\distro\illumos\assemble.cmd" "!PROFILE!" "!SYSROOT!" || exit /b 1

set "STACK="
if /I "!FORMAT!"=="raw" call "!SCRIPT_DIR!\illumos_raw.cmd" "!SYSROOT!" "!OUTPUT!" 20 || exit /b 1
if /I "!FORMAT!"=="qcow2" call "!SCRIPT_DIR!\illumos_qcow2.cmd" "!SYSROOT!" "!OUTPUT!" 20 || exit /b 1
if /I "!FORMAT!"=="box" (
    set "QCOW_TMP=!REPO_ROOT!\build\images\qemu\illumos.qcow2"
    call "!SCRIPT_DIR!\illumos_qcow2.cmd" "!SYSROOT!" "!QCOW_TMP!" 20 || exit /b 1
    set "STACK="
    call "!SCRIPT_DIR!\illumos_vagrant_box.cmd" "!QCOW_TMP!" "!OUTPUT!" "qemu" || exit /b 1
)
if /I "!FORMAT!"=="vhd" call "!SCRIPT_DIR!\illumos_vhd.cmd" "!SYSROOT!" "!OUTPUT!" 20 || exit /b 1
if /I "!FORMAT!"=="vmdk" call "!SCRIPT_DIR!\illumos_vmdk.cmd" "!SYSROOT!" "!OUTPUT!" 20 || exit /b 1
if /I "!FORMAT!"=="iso" call "!SCRIPT_DIR!\illumos_iso.cmd" "!SYSROOT!" "!OUTPUT!" || exit /b 1
if /I "!FORMAT!"=="zfs-stream" call "!SCRIPT_DIR!\zfs_stream.cmd" "!SYSROOT!" "!OUTPUT!" || exit /b 1
if /I "!FORMAT!"=="direct-kernel" call "!SCRIPT_DIR!\direct_kernel.cmd" "--kernel=illumos" "!SYSROOT!" "!OUTPUT!" || exit /b 1

(
    echo format=!FORMAT!
    echo profile=!PROFILE!
) > "!STAMP_FILE!"
echo [OK]       Packaging complete: !OUTPUT!
exit /b 0
