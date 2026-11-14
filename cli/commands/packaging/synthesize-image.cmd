@echo off
:: # synthesize-image.cmd
:: ## Overview
:: Unified kernel-abstracted installer and base-image synthesizer for {component0, component1, ...} on Windows.
:: ## Usage
:: libscript.cmd build-image --kernel=<kernel> --format=<format> --components=<c0,c1,...> [--out=<path>] [--dry-run]

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

set "KERNEL=linux-glibc"
set "OS_FLAVOR="
set "TARGET_ARCH=x86_64"
set "FORMAT=qcow2"
set "COMPONENTS_CSV="
set "PROFILE_JSON="
set "OUT_PATH="
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"

:: ## parse_args
:: Parses CLI flags for synthesize-image.cmd.
:parse_args
set "_A=%~1"
if "!_A!"=="" goto :args_parsed
if /I "!_A!"=="build-image" ( shift & goto :parse_args )
if /I "!_A!"=="build-installer" ( shift & goto :parse_args )
if /I "!_A!"=="--help" goto :show_help
if /I "!_A!"=="-h" goto :show_help
if /I "!_A!"=="/?" goto :show_help
if /I "!_A!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /I "!_A!"=="--allow-stub" ( set "ALLOW_STUB=1" & set "LIBSCRIPT_ALLOW_STUB=1" & shift & goto :parse_args )
if /I "!_A!"=="--offline" ( set "LIBSCRIPT_OFFLINE=1" & shift & goto :parse_args )
if "!_A:~0,9!"=="--kernel=" ( set "KERNEL=!_A:~9!" & shift & goto :parse_args )
if "!_A:~0,12!"=="--os-flavor=" ( set "OS_FLAVOR=!_A:~12!" & shift & goto :parse_args )
if "!_A:~0,7!"=="--arch=" ( set "TARGET_ARCH=!_A:~7!" & shift & goto :parse_args )
if "!_A:~0,9!"=="--format=" ( set "FORMAT=!_A:~9!" & shift & goto :parse_args )
if "!_A:~0,13!"=="--components=" ( set "COMPONENTS_CSV=!_A:~13!" & shift & goto :parse_args )
if "!_A:~0,10!"=="--profile=" ( set "PROFILE_JSON=!_A:~10!" & shift & goto :parse_args )
if "!_A:~0,6!"=="--out=" ( set "OUT_PATH=!_A:~6!" & shift & goto :parse_args )
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for synthesize-image.cmd.
:show_help
echo Usage: libscript.cmd build-image ^| build-installer --kernel=^<kernel^> --format=^<format^> --components=^<c0,c1,...^> [--out=^<path^>] [--dry-run]
exit /b 0

:: ## args_parsed
:: Maps target kernel family and resolves execution plan via resolve_stack.cmd.
:args_parsed
set "OS_FAMILY=linux-glibc"
set "LIBC=glibc"
set "KPROVIDER=linux-lts"
set "INIT_PROV=systemd"
set "BOOTLOADER=grub2-efi"
set "RESOLVE_OS=linux"

if /I "!KERNEL!"=="linux-musl" ( set "OS_FAMILY=linux-musl" & set "LIBC=musl" & set "INIT_PROV=openrc" )
if /I "!KERNEL!"=="freebsd" ( set "OS_FAMILY=freebsd" & set "LIBC=bsd-libc" & set "KPROVIDER=freebsd-kernel" & set "INIT_PROV=bsd-rc" & set "BOOTLOADER=freebsd-loader" & set "RESOLVE_OS=freebsd" )
if /I "!KERNEL!"=="illumos" ( set "OS_FAMILY=illumos" & set "LIBC=illumos-libc" & set "KPROVIDER=illumos-gate" & set "INIT_PROV=smf" & set "BOOTLOADER=illumos-loader" & set "RESOLVE_OS=sunos" )
if /I "!KERNEL!"=="sunos" ( set "OS_FAMILY=illumos" & set "LIBC=illumos-libc" & set "KPROVIDER=illumos-gate" & set "INIT_PROV=smf" & set "BOOTLOADER=illumos-loader" & set "RESOLVE_OS=sunos" )
if /I "!KERNEL!"=="unikraft" ( set "OS_FAMILY=unikernel-unikraft" & set "LIBC=musl" & set "KPROVIDER=unikraft-core" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=unikraft" )
if /I "!KERNEL!"=="unikernel-unikraft" ( set "OS_FAMILY=unikernel-unikraft" & set "LIBC=musl" & set "KPROVIDER=unikraft-core" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=unikraft" )
if /I "!KERNEL!"=="nanos" ( set "OS_FAMILY=unikernel-nanos" & set "LIBC=glibc" & set "KPROVIDER=nanos-kernel" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=nanos" )
if /I "!KERNEL!"=="unikernel-nanos" ( set "OS_FAMILY=unikernel-nanos" & set "LIBC=glibc" & set "KPROVIDER=nanos-kernel" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=nanos" )
if /I "!KERNEL!"=="osv" ( set "OS_FAMILY=unikernel-osv" & set "LIBC=glibc" & set "KPROVIDER=osv-kernel" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=osv" )
if /I "!KERNEL!"=="unikernel-osv" ( set "OS_FAMILY=unikernel-osv" & set "LIBC=glibc" & set "KPROVIDER=osv-kernel" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=osv" )
if /I "!KERNEL!"=="rumprun" ( set "OS_FAMILY=unikernel-rumprun" & set "LIBC=rump-libc" & set "KPROVIDER=rumprun-hw" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=rumprun" )
if /I "!KERNEL!"=="unikernel-rumprun" ( set "OS_FAMILY=unikernel-rumprun" & set "LIBC=rump-libc" & set "KPROVIDER=rumprun-hw" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=rumprun" )
if /I "!KERNEL!"=="mirageos" ( set "OS_FAMILY=unikernel-mirageos" & set "LIBC=mirage-ocaml" & set "KPROVIDER=mirage-solo5-hvt" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=mirageos" )
if /I "!KERNEL!"=="unikernel-mirageos" ( set "OS_FAMILY=unikernel-mirageos" & set "LIBC=mirage-ocaml" & set "KPROVIDER=mirage-solo5-hvt" & set "INIT_PROV=unikernel-entrypoint" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=mirageos" )

if "!OUT_PATH!"=="" set "OUT_PATH=!LIBSCRIPT_ROOT_DIR!\build\synthesis\!OS_FAMILY!.!FORMAT!"
set "WORK_BASE=!LIBSCRIPT_ROOT_DIR!\build\synthesis\.work-!OS_FAMILY!-!TARGET_ARCH!"
set "SYSROOT_DIR=!WORK_BASE!\sysroot"
if not exist "!WORK_BASE!" mkdir "!WORK_BASE!"
if not exist "!SYSROOT_DIR!" mkdir "!SYSROOT_DIR!"

call :ensure_jq || exit /b 1

set "GEN_OS_CONFIG=!WORK_BASE!\os-config.generated.json"
set "GEN_PLAN=!WORK_BASE!\execution-plan.generated.json"
jq -n --arg os_fam "!OS_FAMILY!" --arg arch "!TARGET_ARCH!" --arg libc "!LIBC!" --arg kprov "!KPROVIDER!" --arg iprov "!INIT_PROV!" --arg bl "!BOOTLOADER!" --arg csv "!COMPONENTS_CSV!" "{schema_version:\"1.0.0\",profile_name:(\"synthesized-\"+$os_fam),target:{arch:$arch,os_family:$os_fam,libc:$libc},kernel:{provider:$kprov,config_method:\"defconfig\"},init_system:{provider:$iprov},storage:{disk_size_gib:16,partition_table:\"gpt\",boot_mode:\"uefi\",bootloader:$bl},components:($csv|split(\",\")|map(select(length>0)))}" > "!GEN_OS_CONFIG!"

set "LIBSCRIPT_TARGET_OS=!RESOLVE_OS!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\resolve_stack.cmd" "!GEN_OS_CONFIG!" "!GEN_PLAN!"
if errorlevel 1 exit /b 1

if "!DRY_RUN!"=="1" (
    set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT_DIR!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\execute_plan.cmd" "!GEN_PLAN!" --dry-run
    exit /b !ERRORLEVEL!
)

set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT_DIR!"
set "LIBSCRIPT_IMAGE_BUILD=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\execute_plan.cmd" "!GEN_PLAN!" || exit /b 1

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\cli\commands\packaging\package-as.cmd" "!FORMAT!" "!SYSROOT_DIR!" "!OUT_PATH!"
exit /b !ERRORLEVEL!

:: ## ensure_jq
:: Bootstraps _lib\utilities\jq when jq is not already available on PATH.
:ensure_jq
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
where jq >nul 2>&1
if not errorlevel 1 exit /b 0
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" install jq latest >nul 2>&1
if exist "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" call "!LIBSCRIPT_ROOT_DIR!\_lib\utilities\jq\env.cmd" >nul 2>&1
where jq >nul 2>&1
exit /b !ERRORLEVEL!
