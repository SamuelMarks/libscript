@echo off
:: # unikernel_img.cmd
:: ## Overview
:: Kernel-dispatching unikernel packager on Windows supporting Unikraft, Nanos/Ops, OSv,
:: Rumprun, MirageOS, declarative `--profile` / `--format` synthesis, and UEFI/GPT cloud disk wrappers.
:: ## Usage
:: unikernel_img.cmd [--profile <path|preset>] [--format <elf|qcow2|raw|iso|uefi-gpt|azure-vhd|direct-kernel>] [--output <path>] [--framework=<fw>] [--vmm=<vmm>] [--cloud-boot=uefi-gpt] [--dry-run] [--allow-stub-sdk] [app_dir] [output_elf]

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

set "FRAMEWORK=unikraft"
if not "%LIBSCRIPT_UNIKERNEL_FRAMEWORK%"=="" set "FRAMEWORK=%LIBSCRIPT_UNIKERNEL_FRAMEWORK%"
set "VMM=qemu"
set "VMM_EXPLICIT=0"
set "TENDER_VAL="
set "TAP_DEV=tap0"
set "CLOUD_BOOT=none"
set "FORMAT=elf"
set "PROFILE="
set "OUT_OVERRIDE="
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
set "POS_APP="
set "POS_OUT="
goto :parse_flags

:: ## parse_flags
:: Parses CLI flags for unikernel_img.cmd.
:parse_flags
if "%~1"=="" goto :flags_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_flags )
if /i "!_a!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_flags )
if /i "!_a:~0,10!"=="--profile=" ( set "PROFILE=!_a:~10!" & shift & goto :parse_flags )
if /i "!_a!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_flags )
if /i "!_a!"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_flags )
if /i "!_a:~0,9!"=="--format=" ( set "FORMAT=!_a:~9!" & shift & goto :parse_flags )
if /i "!_a!"=="--output" ( set "OUT_OVERRIDE=%~2" & shift & shift & goto :parse_flags )
if /i "!_a!"=="--out" ( set "OUT_OVERRIDE=%~2" & shift & shift & goto :parse_flags )
if /i "!_a!"=="-o" ( set "OUT_OVERRIDE=%~2" & shift & shift & goto :parse_flags )
if /i "!_a:~0,9!"=="--output=" ( set "OUT_OVERRIDE=!_a:~9!" & shift & goto :parse_flags )
if /i "!_a:~0,6!"=="--out=" ( set "OUT_OVERRIDE=!_a:~6!" & shift & goto :parse_flags )
if /i "!_a!"=="--framework" ( set "FRAMEWORK=%~2" & shift & shift & goto :parse_flags )
if /i "!_a:~0,12!"=="--framework=" ( set "FRAMEWORK=!_a:~12!" & shift & goto :parse_flags )
if /i "!_a!"=="--vmm" ( set "VMM=%~2" & set "VMM_EXPLICIT=1" & shift & shift & goto :parse_flags )
if /i "!_a:~0,6!"=="--vmm=" ( set "VMM=!_a:~6!" & set "VMM_EXPLICIT=1" & shift & goto :parse_flags )
if /i "!_a!"=="--tender" ( set "TENDER_VAL=%~2" & set "VMM_EXPLICIT=1" & shift & shift & goto :parse_flags )
if /i "!_a:~0,9!"=="--tender=" ( set "TENDER_VAL=!_a:~9!" & set "VMM_EXPLICIT=1" & shift & goto :parse_flags )
if /i "!_a!"=="--tap" ( set "TAP_DEV=%~2" & shift & shift & goto :parse_flags )
if /i "!_a:~0,6!"=="--tap=" ( set "TAP_DEV=!_a:~6!" & shift & goto :parse_flags )
if /i "!_a!"=="--cloud-boot" ( set "CLOUD_BOOT=%~2" & shift & shift & goto :parse_flags )
if /i "!_a:~0,13!"=="--cloud-boot=" ( set "CLOUD_BOOT=!_a:~13!" & shift & goto :parse_flags )
if /i "!_a!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_flags )
if /i "!_a!"=="--strict" ( set "ALLOW_STUB=0" & shift & goto :parse_flags )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_flags )
if /i "!_a!"=="--allow-stub-sdk" ( set "ALLOW_STUB=1" & shift & goto :parse_flags )
if /i "!_a!"=="--offline" ( set "LIBSCRIPT_OFFLINE=1" & shift & goto :parse_flags )
if "!POS_APP!"=="" ( set "POS_APP=!_a!" ) else ( if "!POS_OUT!"=="" set "POS_OUT=!_a!" )
shift
goto :parse_flags

:: ## show_help
:: Displays usage instructions for unikernel_img.cmd.
:show_help
echo Usage: %~nx0 [--profile ^<path^|preset^>] [--format ^<elf^|qcow2^|raw^|iso^|uefi-gpt^|azure-vhd^|direct-kernel^>] [--output ^<path^>] [--framework=unikraft^|nanos^|osv^|rumprun^|mirageos] [--vmm=^<vmm^>] [--cloud-boot=uefi-gpt^|none] [--dry-run] [--allow-stub-sdk] [app_dir] [output_elf]
exit /b 0

:: ## flags_done
:: Validates inputs, checks idempotency stamp, and builds or wraps the unikernel artifact.
:flags_done
set "PNAME=app"
if not "!PROFILE!"=="" (
    set "_UP=!PROFILE:/=\!"
    if not exist "!_UP!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_UP!.json" set "_UP=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_UP!.json"
    if not exist "!_UP!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\unikernel\!_UP!.json" set "_UP=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\unikernel\!_UP!.json"
    if not exist "!_UP!" if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\unikernel\openedx\!_UP!.json" set "_UP=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\unikernel\openedx\!_UP!.json"
    set "PROFILE=!_UP!"
    if not exist "!PROFILE!" (
        echo [ERROR] Unikernel profile not found: !PROFILE! >&2
        exit /b 1
    )
    for %%F in ("!PROFILE!") do set "PNAME=%%~nF"
    findstr /I /C:"osv" "!PROFILE!" >nul 2>&1 && set "FRAMEWORK=osv"
    findstr /I /C:"mirage" "!PROFILE!" >nul 2>&1 && set "FRAMEWORK=mirageos"
    findstr /I /C:"nanos" "!PROFILE!" >nul 2>&1 && set "FRAMEWORK=nanos"
    findstr /I /C:"rumprun" "!PROFILE!" >nul 2>&1 && set "FRAMEWORK=rumprun"
    findstr /I /C:"unikraft" "!PROFILE!" >nul 2>&1 && set "FRAMEWORK=unikraft"
    if "!VMM_EXPLICIT!"=="0" (
        findstr /I /C:"solo5-hvt" "!PROFILE!" >nul 2>&1 && set "VMM=solo5-hvt"
        findstr /I /C:"solo5-spt" "!PROFILE!" >nul 2>&1 && set "VMM=solo5-spt"
    )
)

if /I "!TENDER_VAL!"=="hvt" set "VMM=solo5-hvt"
if /I "!TENDER_VAL!"=="solo5-hvt" set "VMM=solo5-hvt"
if /I "!TENDER_VAL!"=="spt" set "VMM=solo5-spt"
if /I "!TENDER_VAL!"=="solo5-spt" set "VMM=solo5-spt"
if /I "!TENDER_VAL!"=="xen" set "VMM=xen"

set "FRAMEWORK=!FRAMEWORK:unikernel-=!"
if /I "!FORMAT!"=="uefi-gpt" set "CLOUD_BOOT=uefi-gpt"
if /I "!FORMAT!"=="azure-vhd" set "CLOUD_BOOT=uefi-gpt"

set "APP_DIR=!POS_APP!"
if "!APP_DIR!"=="" set "APP_DIR=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
set "OUT_ELF=!OUT_OVERRIDE!"
if "!OUT_ELF!"=="" set "OUT_ELF=!POS_OUT!"
if "!OUT_ELF!"=="" (
    if not "!PROFILE!"=="" (
        set "OUT_ELF=!LIBSCRIPT_ROOT_DIR!\build\images\unikernel\!PNAME!.unikernel.elf"
        if /I "!FORMAT!"=="uefi-gpt" set "OUT_ELF=!LIBSCRIPT_ROOT_DIR!\build\images\unikernel\!PNAME!.uefi-gpt.raw"
        if /I "!FORMAT!"=="azure-vhd" set "OUT_ELF=!LIBSCRIPT_ROOT_DIR!\build\images\unikernel\!PNAME!.vhd"
    ) else (
        set "OUT_ELF=!LIBSCRIPT_ROOT_DIR!\build\images\unikernel\app.unikernel.elf"
    )
)

if "!DRY_RUN!"=="1" (
    if not "!PROFILE!"=="" (
        set "STACK="
        call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=unikernel-!FRAMEWORK!" "--profile=!PROFILE!" "--format=unikernel" "--out=!OUT_ELF!" --dry-run
        exit /b !ERRORLEVEL!
    )
    echo [DRYRUN] Unikernel ^(!FRAMEWORK!, vmm=!VMM!, format=!FORMAT!^) target verified -^> !OUT_ELF!
    exit /b 0
)

set "STAMP_FILE=!OUT_ELF!.stamp"
if exist "!STAMP_FILE!" if exist "!OUT_ELF!" (
    findstr /B /C:"vmm=!VMM!" "!STAMP_FILE!" >nul 2>&1
    if not errorlevel 1 (
        findstr /B /C:"format=!FORMAT!" "!STAMP_FILE!" >nul 2>&1
        if not errorlevel 1 (
            echo [SKIP] Unikernel image already synthesized: !OUT_ELF!
            exit /b 0
        )
    )
)

for %%D in ("!OUT_ELF!") do if not exist "%%~dpD" mkdir "%%~dpD"
if not exist "!APP_DIR!" mkdir "!APP_DIR!"

set "_SDK_BIN=kraft"
if /i "!FRAMEWORK!"=="nanos" set "_SDK_BIN=ops"
if /i "!FRAMEWORK!"=="ops" set "_SDK_BIN=ops"
if /i "!FRAMEWORK!"=="osv" set "_SDK_BIN=capstan"
if /i "!FRAMEWORK!"=="rumprun" set "_SDK_BIN=rumpbake"
if /i "!FRAMEWORK!"=="mirageos" set "_SDK_BIN=mirage"

where "!_SDK_BIN!" >nul 2>&1
if errorlevel 1 (
    if not "!ALLOW_STUB!"=="1" (
        echo [ERROR] !FRAMEWORK! unikernel SDK ^(!_SDK_BIN!^) not found on host ^(pass --allow-stub-sdk only for offline descriptor tests^). >&2
        exit /b 1
    )
    echo LibScript Unikernel ^(!FRAMEWORK!/!VMM!/!CLOUD_BOOT!^) Stub> "!OUT_ELF!"
    call :emit_vmm_descriptors
    if /i "!CLOUD_BOOT!"=="uefi-gpt" call :wrap_uefi_gpt
    (
        echo mode=stub
        echo framework=!FRAMEWORK!
        echo vmm=!VMM!
        echo format=!FORMAT!
        echo cloud_boot=!CLOUD_BOOT!
    ) > "!STAMP_FILE!"
    echo [WARN] !FRAMEWORK! SDK not on host; emitted unikernel descriptor and stub: !OUT_ELF!
    exit /b 0
)

call "!LIBSCRIPT_ROOT_DIR!\engine\common\vm_builder.cmd" "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\unikernel_img.sh" --framework=!FRAMEWORK! --vmm=!VMM! --format=!FORMAT! --cloud-boot=!CLOUD_BOOT! "!APP_DIR!" "!OUT_ELF!"
exit /b !ERRORLEVEL!

:: ## emit_vmm_descriptors
:: Emits Firecracker microVM JSON and Solo5 hvt/spt tender + TAP probe descriptors on Windows.
:emit_vmm_descriptors
set "_ESC_OUT=!OUT_ELF:\=\\!"
if /I "!VMM!"=="firecracker" (
    (
        echo {
        echo   "boot-source": { "kernel_image_path": "!_ESC_OUT!", "boot_args": "console=ttyS0 reboot=k panic=1 pci=off" },
        echo   "machine-config": { "vcpu_count": 1, "mem_size_mib": 256, "smt": false },
        echo   "network-interfaces": [ { "iface_id": "eth0", "host_dev_name": "!TAP_DEV!" } ]
        echo }
    ) > "!OUT_ELF!.firecracker.json"
)
if /I "!VMM!"=="solo5-hvt" goto :emit_solo5_meta
if /I "!VMM!"=="solo5-spt" goto :emit_solo5_meta
exit /b 0

:: ## emit_solo5_meta
:: Writes Solo5 manifest v1 and tender TAP health probe JSON metadata on Windows.
:emit_solo5_meta
(
    echo {
    echo   "type": "solo5.manifest",
    echo   "version": 1,
    echo   "devices": [ { "name": "service", "type": "NET_BASIC" } ]
    echo }
) > "!OUT_ELF!.solo5-manifest.json"
(
    echo {
    echo   "framework": "!FRAMEWORK!",
    echo   "tender": "!VMM!",
    echo   "tap_device": "!TAP_DEV!",
    echo   "guest_ipv4": "10.0.0.2/24",
    echo   "host_gateway_ipv4": "10.0.0.1",
    echo   "health_probe": "https://10.0.0.2:8443/healthz"
    echo }
) > "!OUT_ELF!.tender.json"
exit /b 0

:: ## wrap_uefi_gpt
:: Writes OVMF UEFI/GPT and optional 1 MiB-aligned Azure Hyper-V Gen2 VHD descriptors on Windows.
:wrap_uefi_gpt
if not exist "!APP_DIR!\boot\efi\EFI\BOOT" mkdir "!APP_DIR!\boot\efi\EFI\BOOT"
copy /Y "!OUT_ELF!" "!APP_DIR!\boot\efi\EFI\BOOT\BOOTX64.EFI" >nul
(
    echo {
    echo   "firmware": "OVMF",
    echo   "boot_mode": "uefi-gpt",
    echo   "partition_table": "gpt",
    echo   "efi_binary": "/EFI/BOOT/BOOTX64.EFI",
    echo   "framework": "!FRAMEWORK!",
    echo   "vmm": "!VMM!"
    echo }
) > "!OUT_ELF!.uefi-gpt.json"
if /I "!FORMAT!"=="azure-vhd" (
    del /f /q "!OUT_ELF!" >nul 2>&1
    fsutil file createnew "!OUT_ELF!" 1049088 >nul 2>&1
    (
        echo {
        echo   "cloud": "azure",
        echo   "vm_generation": "V2",
        echo   "hypervisor": "hyperv-gen2",
        echo   "firmware": "OVMF",
        echo   "boot_mode": "uefi-gpt",
        echo   "partition_table": "gpt",
        echo   "vhd_type": "fixed",
        echo   "vhd_alignment_mib": 1,
        echo   "footer_cookie": "conectix",
        echo   "framework": "!FRAMEWORK!"
        echo }
    ) > "!OUT_ELF!.azure-vhd.json"
)
exit /b 0
