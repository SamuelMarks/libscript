@echo off
:: # register_bento_boxes.cmd
::
:: ## Overview
:: Discovers built Vagrant .qemu.box / .libvirt.box / .utm.box images in ..\bento\builds\build_complete\,
:: validates non-DOS and DOS Packer templates plus standalone builders in ..\bento\, and registers target OS
:: boxes (including bento/msdos-{1.25,2.0,4.0}, bento/freedos-{1.3,1.4}, bento/freedos, and legacy anondos/*
:: aliases) idempotently in the host's Vagrant installation.
::
:: ## Usage
:: tests\register_bento_boxes.cmd [--bento-dir <path>] [--bento-prefix <prefix>] [--arch <aarch64|x86_64>] [--force] [--validate-only]

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

if not defined BENTO_DIR set "BENTO_DIR=%LIBSCRIPT_ROOT_DIR%\..\bento"
if not defined BENTO_PREFIX set "BENTO_PREFIX=bento"
set "FORCE_FLAG="
set "VALIDATE_ONLY=0"

call :parse_args %*
if errorlevel 2 exit /b 0
if errorlevel 1 exit /b 1

call :detect_bento_host_arch
call :validate_bento_pkrvars

if "!VALIDATE_ONLY!"=="1" exit /b 0

where vagrant >nul 2>&1
if errorlevel 1 (
    echo [WARN] vagrant CLI not found on host; skipping box registration. >&2
    exit /b 0
)

set "BUILD_COMPLETE=!BENTO_DIR!\builds\build_complete"

call :resolve_box_artifact "omnios-braich" "qemu.box" BOX_OMNIOS
call :register_box "!BENTO_PREFIX!/omnios" "!BOX_OMNIOS!" "qemu"

call :resolve_box_artifact "alpine-3.24" "qemu.box" BOX_ALPINE
call :register_box "!BENTO_PREFIX!/alpine-3.24" "!BOX_ALPINE!" "qemu"

call :resolve_box_artifact "debian-13.6" "qemu.box" BOX_DEBIAN
call :register_box "!BENTO_PREFIX!/debian-13" "!BOX_DEBIAN!" "qemu"

call :resolve_box_artifact "rockylinux-10.2" "qemu.box" BOX_ROCKY
call :resolve_box_artifact "almalinux-9.8" "qemu.box" BOX_ALMA
if exist "!BOX_ROCKY!" (
    call :register_box "!BENTO_PREFIX!/rockylinux-10.2" "!BOX_ROCKY!" "qemu"
) else if exist "!BOX_ALMA!" (
    call :register_box "!BENTO_PREFIX!/rockylinux-10.2" "!BOX_ALMA!" "qemu"
) else (
    call :register_box "!BENTO_PREFIX!/rockylinux-10.2" "!BOX_ROCKY!" "qemu"
)

call :resolve_box_artifact "freebsd-15.1" "qemu.box" BOX_FREEBSD
call :register_box "!BENTO_PREFIX!/freebsd-15.1" "!BOX_FREEBSD!" "qemu"

if exist "!BUILD_COMPLETE!\macos-27.2-aarch64.utm.box" (
    call :register_box "!BENTO_PREFIX!/macos-27.2-arm64" "!BUILD_COMPLETE!\macos-27.2-aarch64.utm.box" "utm"
    call :register_box "!BENTO_PREFIX!/macos-14-arm64" "!BUILD_COMPLETE!\macos-27.2-aarch64.utm.box" "utm"
) else (
    call :register_box "!BENTO_PREFIX!/macos-14-arm64" "!BUILD_COMPLETE!\macos-14-aarch64.utm.box" "utm"
)

call :resolve_box_artifact "windows-11" "qemu.box" BOX_WIN11
call :register_box "!BENTO_PREFIX!/windows-11" "!BOX_WIN11!" "qemu"

call :resolve_box_artifact "msdos-1.25" "qemu.box" BOX_MSDOS_125
call :resolve_box_artifact "msdos-2.0" "qemu.box" BOX_MSDOS_20
call :resolve_box_artifact "msdos-4.0" "qemu.box" BOX_MSDOS_40
call :resolve_box_artifact "freedos-1.3" "qemu.box" BOX_FREEDOS_13
call :resolve_box_artifact "freedos-1.4" "qemu.box" BOX_FREEDOS_14

call :register_box "!BENTO_PREFIX!/msdos-1.25" "!BOX_MSDOS_125!" "qemu"
call :register_box "!BENTO_PREFIX!/msdos-2.0" "!BOX_MSDOS_20!" "qemu"
call :register_box "!BENTO_PREFIX!/msdos-4.0" "!BOX_MSDOS_40!" "qemu"
call :register_box "!BENTO_PREFIX!/freedos-1.3" "!BOX_FREEDOS_13!" "qemu"
call :register_box "!BENTO_PREFIX!/freedos-1.4" "!BOX_FREEDOS_14!" "qemu"

if exist "!BOX_FREEDOS_14!" (
    call :register_box "!BENTO_PREFIX!/freedos" "!BOX_FREEDOS_14!" "qemu"
) else if exist "!BOX_FREEDOS_13!" (
    call :register_box "!BENTO_PREFIX!/freedos" "!BOX_FREEDOS_13!" "qemu"
)

if /i not "!BENTO_PREFIX!"=="anondos" (
    call :register_box "anondos/msdos-1.25" "!BOX_MSDOS_125!" "qemu"
    call :register_box "anondos/msdos-2.0" "!BOX_MSDOS_20!" "qemu"
    call :register_box "anondos/msdos-4.0" "!BOX_MSDOS_40!" "qemu"
    call :register_box "anondos/freedos-1.3" "!BOX_FREEDOS_13!" "qemu"
    if exist "!BOX_FREEDOS_14!" (
        call :register_box "anondos/freedos-1.4" "!BOX_FREEDOS_14!" "qemu"
    ) else if exist "!BOX_FREEDOS_13!" (
        call :register_box "anondos/freedos-1.4" "!BOX_FREEDOS_13!" "qemu"
    ) else (
        call :register_box "anondos/freedos-1.4" "!BOX_FREEDOS_14!" "qemu"
    )
)

echo === Host Vagrant Box Inventory ===
vagrant box list
exit /b 0

:: ## parse_args
:: Parses CLI flags for register_bento_boxes.cmd.
:parse_args
if "%~1"=="" exit /b 0
set "_ARG=%~1"
if /i "!_ARG!"=="--help" goto :show_usage
if /i "!_ARG!"=="-h" goto :show_usage
if /i "!_ARG!"=="/?" goto :show_usage
if /i "!_ARG!"=="-?" goto :show_usage
if /i "!_ARG!"=="--force" (
    set "FORCE_FLAG=--force"
    shift
    goto :parse_args
)
if /i "!_ARG!"=="--validate-only" (
    set "VALIDATE_ONLY=1"
    shift
    goto :parse_args
)
if /i "!_ARG!"=="--bento-dir" (
    set "BENTO_DIR=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_ARG:~0,12!"=="--bento-dir=" (
    set "BENTO_DIR=!_ARG:~12!"
    shift
    goto :parse_args
)
if /i "!_ARG!"=="--bento-prefix" (
    set "BENTO_PREFIX=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_ARG:~0,15!"=="--bento-prefix=" (
    set "BENTO_PREFIX=!_ARG:~15!"
    shift
    goto :parse_args
)
if /i "!_ARG!"=="--arch" (
    set "BENTO_HOST_ARCH=%~2"
    shift
    shift
    goto :parse_args
)
if /i "!_ARG:~0,7!"=="--arch=" (
    set "BENTO_HOST_ARCH=!_ARG:~7!"
    shift
    goto :parse_args
)
shift
goto :parse_args

:: ## show_usage
:: Prints usage help and returns status 2 to terminate cleanly.
:show_usage
echo Usage: %~nx0 [--bento-dir ^<path^>] [--bento-prefix ^<prefix^>] [--arch ^<aarch64^|x86_64^>] [--force] [--validate-only]
exit /b 2

:: ## detect_bento_host_arch
:: Resolves the canonical Bento host architecture string (aarch64 or x86_64) on Windows.
:detect_bento_host_arch
if defined BENTO_HOST_ARCH (
    if /i "!BENTO_HOST_ARCH!"=="arm64" set "BENTO_HOST_ARCH=aarch64"
    if /i "!BENTO_HOST_ARCH!"=="amd64" set "BENTO_HOST_ARCH=x86_64"
    exit /b 0
)
if /i "%PROCESSOR_ARCHITECTURE%"=="ARM64" (
    set "BENTO_HOST_ARCH=aarch64"
) else (
    set "BENTO_HOST_ARCH=x86_64"
)
exit /b 0

:: ## resolve_box_artifact
:: Resolves a built Vagrant .box file in builds\build_complete\ preferring host arch with cross-arch fallback.
:resolve_box_artifact
set "_R_STEM=%~1"
set "_R_EXT=%~2"
set "_R_VAR=%~3"
set "_R_BC=!BENTO_DIR!\builds\build_complete"
for %%A in ("!BENTO_HOST_ARCH!" "aarch64" "x86_64" "i386") do (
    if exist "!_R_BC!\!_R_STEM!-%%~A.!_R_EXT!" (
        set "!_R_VAR!=!_R_BC!\!_R_STEM!-%%~A.!_R_EXT!"
        exit /b 0
    )
)
set "!_R_VAR!=!_R_BC!\!_R_STEM!-!BENTO_HOST_ARCH!.!_R_EXT!"
exit /b 0

:: ## validate_bento_pkrvars
:: Validates that non-DOS and DOS target OS Packer templates and standalone DOS builders exist in ..\bento\.
:validate_bento_pkrvars
if not exist "!BENTO_DIR!\" (
    echo [WARN] Bento directory not found at !BENTO_DIR!; skipping pkrvars check. >&2
    exit /b 0
)
echo ==^> Validating Bento Packer templates ^& DOS builders in !BENTO_DIR! ^(host arch: !BENTO_HOST_ARCH!^)...
for %%P in ("os_pkrvars\omnios\omnios-braich-aarch64.pkrvars.hcl" "os_pkrvars\alpine\alpine-3.24-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\debian\debian-13-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\rockylinux\rockylinux-10-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\freebsd\freebsd-15-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\macos\macos-27-aarch64.pkrvars.hcl" "os_pkrvars\macos\macos-14-aarch64.pkrvars.hcl" "os_pkrvars\windows\windows-11-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\freedos\freedos-1.3-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\freedos\freedos-1.4-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\msdos\msdos-1.25-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\msdos\msdos-2.0-!BENTO_HOST_ARCH!.pkrvars.hcl" "os_pkrvars\msdos\msdos-4.0-!BENTO_HOST_ARCH!.pkrvars.hcl" "freedos-builder.sh" "freedos-builder.cmd" "msdos-builder.sh" "msdos-builder.cmd") do (
    if exist "!BENTO_DIR!\%%~P" (
        echo [PASS] Found %%~P
    ) else (
        echo [WARN] Missing %%~P in !BENTO_DIR! >&2
    )
)
exit /b 0

:: ## ensure_libvirt_qemu_links
:: Idempotently links libvirt provider directories to qemu inside VAGRANT_HOME\boxes on Windows.
:ensure_libvirt_qemu_links
set "_L_BOX=%~1"
set "_L_VSLASH=!_L_BOX:/=-VAGRANTSLASH-!"
set "_L_VAG_HOME=%VAGRANT_HOME%"
if "!_L_VAG_HOME!"=="" set "_L_VAG_HOME=%USERPROFILE%\.vagrant.d"
for %%V in (arm64 amd64) do (
    if exist "!_L_VAG_HOME!\boxes\!_L_VSLASH!\0\%%V\qemu\" (
        if not exist "!_L_VAG_HOME!\boxes\!_L_VSLASH!\0\%%V\libvirt\" (
            rmdir /q "!_L_VAG_HOME!\boxes\!_L_VSLASH!\0\%%V\libvirt" >nul 2>&1
            mklink /J "!_L_VAG_HOME!\boxes\!_L_VSLASH!\0\%%V\libvirt" "!_L_VAG_HOME!\boxes\!_L_VSLASH!\0\%%V\qemu" >nul 2>&1
        )
    )
)
exit /b 0

:: ## register_box
:: Registers a single box in Vagrant idempotently unless --force is passed.
:register_box
set "_BNAME=%~1"
set "_BFILE=%~2"
set "_BPROV=%~3"
if "!_BPROV!"=="" set "_BPROV=qemu"
if "!FORCE_FLAG!"=="" (
    vagrant box list 2>nul | findstr /R /C:"^!_BNAME! .*!_BPROV!" >nul 2>&1
    if not errorlevel 1 (
        echo [OK]   Box !_BNAME! ^(!_BPROV!^) is already registered in host Vagrant.
        call :ensure_libvirt_qemu_links "!_BNAME!"
        exit /b 0
    )
)
if exist "!_BFILE!" (
    echo ==^> Registering !_BNAME! ^(!_BPROV!^) from !_BFILE!...
    vagrant box add --name "!_BNAME!" --provider "!_BPROV!" !FORCE_FLAG! "!_BFILE!"
    if not errorlevel 1 (
        echo [PASS] Registered !_BNAME! ^(!_BPROV!^).
        call :ensure_libvirt_qemu_links "!_BNAME!"
    )
) else (
    echo [WARN] Box file !_BFILE! not found; cannot register !_BNAME!. >&2
)
exit /b 0
