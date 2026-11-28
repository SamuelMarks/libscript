@echo off
:: # synthesize-image.cmd
:: ## Overview
:: Unified kernel-abstracted installer and base-image synthesizer for {component0, component1, ...} on Windows.
:: ## Usage
:: libscript.cmd build-image --kernel=<kernel> [--profile=<file.json>] --format=<format> [--components=<c0,c1,...>] [--out=<path>] [--dry-run]

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

set "KERNEL=linux-glibc"
set "OS_FLAVOR="
set "TARGET_ARCH="
set "ARCH_EXPLICIT=0"
set "RTOS_BOARD=%LIBSCRIPT_RTOS_BOARD%"
set "HYBRID_POD=0"
if "%LIBSCRIPT_RTOS_HYBRID_POD%"=="1" set "HYBRID_POD=1"
set "MCUBOOT_ENABLED=0"
if "%LIBSCRIPT_RTOS_MCUBOOT%"=="1" set "MCUBOOT_ENABLED=1"
set "FORMAT="
set "COMPONENTS_CSV="
set "PROFILE_JSON="
set "OUT_PATH="
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_args

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
if /I "!_A!"=="--hybrid-pod" ( set "HYBRID_POD=1" & shift & goto :parse_args )
if /I "!_A!"=="--mcuboot" ( set "MCUBOOT_ENABLED=1" & shift & goto :parse_args )
if /I "!_A!"=="--strict" ( set "LIBSCRIPT_STRICT_IMAGE_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_args )
if /I "!_A!"=="--allow-stub" ( set "ALLOW_STUB=1" & set "LIBSCRIPT_ALLOW_STUB=1" & shift & goto :parse_args )
if /I "!_A!"=="--offline" ( set "LIBSCRIPT_OFFLINE=1" & shift & goto :parse_args )
if /I "!_A!"=="--kernel" ( set "KERNEL=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,9!"=="--kernel=" ( set "KERNEL=!_A:~9!" & shift & goto :parse_args )
if /I "!_A!"=="--board" ( set "RTOS_BOARD=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,8!"=="--board=" ( set "RTOS_BOARD=!_A:~8!" & shift & goto :parse_args )
if /I "!_A!"=="--os-flavor" ( set "OS_FLAVOR=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,12!"=="--os-flavor=" ( set "OS_FLAVOR=!_A:~12!" & shift & goto :parse_args )
if /I "!_A!"=="--shell" ( set "LIBSCRIPT_DOS_SHELL_PROVIDER=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,8!"=="--shell=" ( set "LIBSCRIPT_DOS_SHELL_PROVIDER=!_A:~8!" & shift & goto :parse_args )
if /I "!_A!"=="--arch" ( set "TARGET_ARCH=%~2" & set "ARCH_EXPLICIT=1" & shift & shift & goto :parse_args )
if /I "!_A:~0,7!"=="--arch=" ( set "TARGET_ARCH=!_A:~7!" & set "ARCH_EXPLICIT=1" & shift & goto :parse_args )
if /I "!_A!"=="--initramfs-compress" ( set "LIBSCRIPT_INITRAMFS_COMPRESS=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,21!"=="--initramfs-compress=" ( set "LIBSCRIPT_INITRAMFS_COMPRESS=!_A:~21!" & shift & goto :parse_args )
if /I "!_A!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,9!"=="--format=" ( set "FORMAT=!_A:~9!" & shift & goto :parse_args )
if /I "!_A!"=="--components" ( set "COMPONENTS_CSV=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,13!"=="--components=" ( set "COMPONENTS_CSV=!_A:~13!" & shift & goto :parse_args )
if /I "!_A!"=="--profile" ( set "PROFILE_JSON=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,10!"=="--profile=" ( set "PROFILE_JSON=!_A:~10!" & shift & goto :parse_args )
if /I "!_A!"=="--out" ( set "OUT_PATH=%~2" & shift & shift & goto :parse_args )
if /I "!_A!"=="--output" ( set "OUT_PATH=%~2" & shift & shift & goto :parse_args )
if /I "!_A:~0,6!"=="--out=" ( set "OUT_PATH=!_A:~6!" & shift & goto :parse_args )
if /I "!_A:~0,9!"=="--output=" ( set "OUT_PATH=!_A:~9!" & shift & goto :parse_args )
shift
goto :parse_args

:: ## show_help
:: Displays usage instructions for synthesize-image.cmd.
:show_help
echo Usage: libscript.cmd build-image ^| build-installer --kernel=^<kernel^> [--profile=^<file.json^>] [--board=^<board^>] --format=^<format^> [--components=^<c0,c1,...^>] [--out=^<path^>] [--dry-run]
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
if /I "!KERNEL!"=="reactos" ( set "OS_FAMILY=reactos" & set "LIBC=msvcrt" & set "KPROVIDER=reactos-ntoskrnl" & set "INIT_PROV=nt-scm" & set "BOOTLOADER=freeldr" & set "RESOLVE_OS=reactos" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i686" & if "!FORMAT!"=="" set "FORMAT=iso" )
if /I "!KERNEL!"=="freedos" ( set "OS_FAMILY=freedos" & set "LIBC=djgpp-libc" & set "KPROVIDER=freedos-kernel" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=freedos-sys" & set "RESOLVE_OS=freedos" & set "DOS_VER=1.4" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i586" & if "!FORMAT!"=="" set "FORMAT=qcow2" )
if /I "!KERNEL!"=="freedos-1.4" ( set "OS_FAMILY=freedos" & set "LIBC=djgpp-libc" & set "KPROVIDER=freedos-kernel" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=freedos-sys" & set "RESOLVE_OS=freedos" & set "DOS_VER=1.4" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i586" & if "!FORMAT!"=="" set "FORMAT=qcow2" )
if /I "!KERNEL!"=="freedos-1.3" ( set "OS_FAMILY=freedos" & set "LIBC=djgpp-libc" & set "KPROVIDER=freedos-kernel" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=freedos-sys" & set "RESOLVE_OS=freedos" & set "DOS_VER=1.3" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i586" & if "!FORMAT!"=="" set "FORMAT=qcow2" )
if /I "!KERNEL!"=="msdos" ( set "OS_FAMILY=msdos" & set "LIBC=djgpp-libc" & set "KPROVIDER=msdos-mit-4.0" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=dos-mbr-vbr" & set "RESOLVE_OS=msdos" & set "DOS_VER=4.0" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i586" & if "!FORMAT!"=="" set "FORMAT=qcow2" )
if /I "!KERNEL!"=="msdos-4.0" ( set "OS_FAMILY=msdos" & set "LIBC=djgpp-libc" & set "KPROVIDER=msdos-mit-4.0" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=dos-mbr-vbr" & set "RESOLVE_OS=msdos" & set "DOS_VER=4.0" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i586" & if "!FORMAT!"=="" set "FORMAT=qcow2" )
if /I "!KERNEL!"=="msdos-2.0" ( set "OS_FAMILY=msdos" & set "LIBC=dos16-libc" & set "KPROVIDER=msdos-mit-2.0" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=dos-mbr-vbr" & set "RESOLVE_OS=msdos" & set "DOS_VER=2.0" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i8086" & if "!FORMAT!"=="" set "FORMAT=floppy-img" )
if /I "!KERNEL!"=="msdos-1.25" ( set "OS_FAMILY=msdos" & set "LIBC=dos-fcb-none" & set "KPROVIDER=msdos-mit-1.25" & set "INIT_PROV=dos-autoexec" & set "BOOTLOADER=dos-vbr-flat" & set "RESOLVE_OS=msdos" & set "DOS_VER=1.25" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=i8086" & if "!FORMAT!"=="" set "FORMAT=floppy-img" )
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
if /I "!KERNEL!"=="zephyr" ( set "OS_FAMILY=rtos-zephyr" & set "LIBC=picolibc" & set "KPROVIDER=zephyr-lts" & set "INIT_PROV=zephyr-sys-init" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=zephyr" & if "!RTOS_BOARD!"=="" set "RTOS_BOARD=qemu_x86_64" & if "!FORMAT!"=="" set "FORMAT=firmware-elf" )
if /I "!KERNEL!"=="rtos-zephyr" ( set "OS_FAMILY=rtos-zephyr" & set "LIBC=picolibc" & set "KPROVIDER=zephyr-lts" & set "INIT_PROV=zephyr-sys-init" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=zephyr" & if "!RTOS_BOARD!"=="" set "RTOS_BOARD=qemu_x86_64" & if "!FORMAT!"=="" set "FORMAT=firmware-elf" )
if /I "!KERNEL!"=="freertos" ( set "OS_FAMILY=rtos-freertos" & set "LIBC=newlib" & set "KPROVIDER=freertos-lts" & set "INIT_PROV=freertos-scheduler" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=freertos" & if "!RTOS_BOARD!"=="" set "RTOS_BOARD=win32_sim" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=x86_64" & if "!FORMAT!"=="" set "FORMAT=firmware-elf" )
if /I "!KERNEL!"=="rtos-freertos" ( set "OS_FAMILY=rtos-freertos" & set "LIBC=newlib" & set "KPROVIDER=freertos-lts" & set "INIT_PROV=freertos-scheduler" & set "BOOTLOADER=unikernel-direct" & set "RESOLVE_OS=freertos" & if "!RTOS_BOARD!"=="" set "RTOS_BOARD=win32_sim" & if "!TARGET_ARCH!"=="" set "TARGET_ARCH=x86_64" & if "!FORMAT!"=="" set "FORMAT=firmware-elf" )

if "!TARGET_ARCH!"=="" set "TARGET_ARCH=x86_64"
if "!FORMAT!"=="" set "FORMAT=qcow2"
set "NORM_FMT=!FORMAT!"
if /I "!NORM_FMT!"=="iso" set "NORM_FMT=live-iso"
if /I "!NORM_FMT!"=="raw-img" set "NORM_FMT=raw"
if /I "!NORM_FMT!"=="unikernel" set "NORM_FMT=direct-kernel"
if "!MCUBOOT_ENABLED!"=="1" set "BOOTLOADER=mcuboot"
if /I "!FORMAT!"=="mcuboot-signed" ( set "BOOTLOADER=mcuboot" & set "MCUBOOT_ENABLED=1" )

if "!OUT_PATH!"=="" set "OUT_PATH=!LIBSCRIPT_ROOT_DIR!\build\synthesis\!OS_FAMILY!.!FORMAT!"
set "WORK_BASE=!LIBSCRIPT_ROOT_DIR!\build\synthesis\.work-!OS_FAMILY!-!TARGET_ARCH!"
set "SYSROOT_DIR=!WORK_BASE!\sysroot"
if not exist "!WORK_BASE!" mkdir "!WORK_BASE!"
if not exist "!SYSROOT_DIR!" mkdir "!SYSROOT_DIR!"

call :ensure_jq || exit /b 1

set "GEN_OS_CONFIG=!WORK_BASE!\os-config.generated.json"
set "GEN_PLAN=!WORK_BASE!\execution-plan.generated.json"
if not "!PROFILE_JSON!"=="" (
    set "PROFILE_JSON=!PROFILE_JSON:/=\!"
    if exist "!PROFILE_JSON!" (
        set "_JQ_PROF_IN=!PROFILE_JSON:\=/!"
        jq --arg os_fam "!OS_FAMILY!" --arg arch "!TARGET_ARCH!" --arg arch_exp "!ARCH_EXPLICIT!" --arg libc "!LIBC!" --arg kprov "!KPROVIDER!" --arg iprov "!INIT_PROV!" --arg bl "!BOOTLOADER!" --arg fmt "!NORM_FMT!" --arg board "!RTOS_BOARD!" --arg hpod "!HYBRID_POD!" --arg mcub "!MCUBOOT_ENABLED!" --arg csv "!COMPONENTS_CSV!" ".target.os_family=(.target.os_family//$os_fam) | .target.arch=(if $arch_exp==\"1\" then $arch else (.target.arch//$arch) end) | .target.libc=(.target.libc//$libc) | .kernel=((.kernel//{config_method:\"defconfig\"}) | .provider=(.provider//$kprov)) | .init_system=((.init_system//{}) | .provider=(.provider//$iprov)) | .storage=((.storage//{disk_size_gib:1,partition_table:\"none\",boot_mode:\"direct-kernel\"}) | .bootloader=(.bootloader//$bl)) | (if ($board|length)>0 then .rtos=((.rtos//{}) | .board=(.board//$board) | (if $hpod==\"1\" then .hybrid_pod=true else . end) | (if $mcub==\"1\" then .mcuboot=((.mcuboot//{}) | .enabled=true) else . end)) else . end) | .output_formats=[$fmt] | .components=(((.components//[])+($csv|split(\",\")|map(select(length>0))))|unique)" "!_JQ_PROF_IN!" > "!GEN_OS_CONFIG!"
    ) else (
        jq -n --arg os_fam "!OS_FAMILY!" --arg arch "!TARGET_ARCH!" --arg libc "!LIBC!" --arg kprov "!KPROVIDER!" --arg iprov "!INIT_PROV!" --arg bl "!BOOTLOADER!" --arg fmt "!NORM_FMT!" --arg board "!RTOS_BOARD!" --arg hpod "!HYBRID_POD!" --arg mcub "!MCUBOOT_ENABLED!" --arg csv "!COMPONENTS_CSV!" "{schema_version:\"1.0.0\",profile_name:(\"synthesized-\"+$os_fam),target:{arch:$arch,os_family:$os_fam,libc:$libc},kernel:{provider:$kprov,config_method:\"defconfig\"},init_system:{provider:$iprov},storage:{disk_size_gib:1,partition_table:\"none\",boot_mode:\"direct-kernel\",bootloader:$bl},output_formats:[$fmt],components:($csv|split(\",\")|map(select(length>0)))} + (if ($board|length)>0 then {rtos:({board:$board}+(if $hpod==\"1\" then {hybrid_pod:true} else {} end)+(if $mcub==\"1\" then {mcuboot:{enabled:true}} else {} end))} else {} end)" > "!GEN_OS_CONFIG!"
    )
) else (
    jq -n --arg os_fam "!OS_FAMILY!" --arg arch "!TARGET_ARCH!" --arg libc "!LIBC!" --arg kprov "!KPROVIDER!" --arg iprov "!INIT_PROV!" --arg bl "!BOOTLOADER!" --arg fmt "!NORM_FMT!" --arg board "!RTOS_BOARD!" --arg hpod "!HYBRID_POD!" --arg mcub "!MCUBOOT_ENABLED!" --arg csv "!COMPONENTS_CSV!" "{schema_version:\"1.0.0\",profile_name:(\"synthesized-\"+$os_fam),target:{arch:$arch,os_family:$os_fam,libc:$libc},kernel:{provider:$kprov,config_method:\"defconfig\"},init_system:{provider:$iprov},storage:{disk_size_gib:1,partition_table:\"none\",boot_mode:\"direct-kernel\",bootloader:$bl},output_formats:[$fmt],components:($csv|split(\",\")|map(select(length>0)))} + (if ($board|length)>0 then {rtos:({board:$board}+(if $hpod==\"1\" then {hybrid_pod:true} else {} end)+(if $mcub==\"1\" then {mcuboot:{enabled:true}} else {} end))} else {} end)" > "!GEN_OS_CONFIG!"
)
if errorlevel 1 exit /b 1

set "LIBSCRIPT_TARGET_OS=!RESOLVE_OS!"
set "LIBSCRIPT_TARGET_ARCH=!TARGET_ARCH!"
set "LIBSCRIPT_RTOS_BOARD=!RTOS_BOARD!"
set "LIBSCRIPT_RTOS_HYBRID_POD=!HYBRID_POD!"
set "LIBSCRIPT_RTOS_MCUBOOT=!MCUBOOT_ENABLED!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\solver\resolve_stack.cmd" "!GEN_OS_CONFIG!" "!GEN_PLAN!"
if errorlevel 1 exit /b 1

if "!DRY_RUN!"=="1" (
    set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT_DIR!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\solver\execute_plan.cmd" "!GEN_PLAN!" --dry-run
    exit /b !ERRORLEVEL!
)

set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT_DIR!"
set "LIBSCRIPT_IMAGE_BUILD=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\solver\execute_plan.cmd" "!GEN_PLAN!" || exit /b 1

if /I "!FORMAT!"=="uki" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\uki.cmd" "--arch=!TARGET_ARCH!" "!SYSROOT_DIR!" "!OUT_PATH!"
    exit /b !ERRORLEVEL!
)
if /I "!FORMAT!"=="direct-kernel" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\direct_kernel.cmd" "--kernel=!RESOLVE_OS!" "--arch=!TARGET_ARCH!" "!SYSROOT_DIR!" "!OUT_PATH!"
    exit /b !ERRORLEVEL!
)

if /I "!FORMAT!"=="firmware-elf" goto :pkg_firmware
if /I "!FORMAT!"=="firmware-bin" goto :pkg_firmware
if /I "!FORMAT!"=="firmware-hex" goto :pkg_firmware
if /I "!FORMAT!"=="firmware-uf2" goto :pkg_firmware
if /I "!FORMAT!"=="mcuboot-signed" goto :pkg_firmware
if /I "!FORMAT!"=="renode-resc" goto :pkg_firmware
if /I "!RESOLVE_OS!"=="reactos" (
    if /I "!FORMAT!"=="iso" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_iso.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
    if /I "!FORMAT!"=="live-iso" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_iso.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
    if /I "!FORMAT!"=="raw" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_raw.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" 8 & exit /b !ERRORLEVEL! )
    if /I "!FORMAT!"=="qcow2" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_qcow2.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" 8 & exit /b !ERRORLEVEL! )
)
if /I "!RESOLVE_OS!"=="freedos" goto :pkg_dos_fmt
if /I "!RESOLVE_OS!"=="msdos" goto :pkg_dos_fmt

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\cli.cmd" "!FORMAT!" "!SYSROOT_DIR!" "!OUT_PATH!"
exit /b !ERRORLEVEL!

:: ## pkg_dos_fmt
:: Dispatches FreeDOS and MIT MS-DOS format exporters.
:pkg_dos_fmt
set "STACK="
if /I "!FORMAT!"=="floppy-img" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_floppy.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="floppy" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_floppy.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="raw" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_raw.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="iso" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_iso.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="live-iso" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_iso.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="qcow2" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_qcow2.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="vmdk" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_vmdk.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="vhd" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_vhd.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
if /I "!FORMAT!"=="vagrant-box" ( call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_vagrant_box.cmd" "!SYSROOT_DIR!" "!OUT_PATH!" & exit /b !ERRORLEVEL! )
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\dos_raw.cmd" "!SYSROOT_DIR!" "!OUT_PATH!"
exit /b !ERRORLEVEL!

:: ## pkg_firmware
:: Invokes firmware_bin.cmd for Zephyr and FreeRTOS firmware artifact formats.
:pkg_firmware
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\firmware_bin.cmd" "--format=!FORMAT!" "--kernel=!RESOLVE_OS!" "--board=!RTOS_BOARD!" "!SYSROOT_DIR!" "!OUT_PATH!"
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
