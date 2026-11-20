@echo off
:: # unikernel.cmd
:: ## Overview
:: Kernel-dispatching unikernel packager on Windows supporting Unikraft, Nanos/Ops, OSv,
:: Rumprun, MirageOS, and `--cloud-boot=uefi-gpt` UEFI/GPT cloud disk wrappers.
:: ## Usage
:: unikernel.cmd [--framework=<fw>] [--vmm=<vmm>] [--cloud-boot=uefi-gpt] [--allow-stub-sdk] [app_dir] [output_elf]

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
set "CLOUD_BOOT=none"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_flags

:: ## parse_flags
:: Parses CLI flags for unikernel.cmd.
:parse_flags
if "%~1"=="" goto :flags_done
set "_a=%~1"
if /i "!_a!"=="--help" goto :show_help
if /i "!_a!"=="-h" goto :show_help
if /i "!_a:~0,12!"=="--framework=" ( set "FRAMEWORK=!_a:~12!" & shift & goto :parse_flags )
if /i "!_a:~0,6!"=="--vmm=" ( set "VMM=!_a:~6!" & shift & goto :parse_flags )
if /i "!_a:~0,13!"=="--cloud-boot=" ( set "CLOUD_BOOT=!_a:~13!" & shift & goto :parse_flags )
if /i "!_a!"=="--strict" ( set "ALLOW_STUB=0" & shift & goto :parse_flags )
if /i "!_a!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_flags )
if /i "!_a!"=="--allow-stub-sdk" ( set "ALLOW_STUB=1" & shift & goto :parse_flags )
goto :flags_done

:: ## show_help
:: Displays usage instructions for unikernel.cmd.
:show_help
echo Usage: unikernel.cmd [--framework=unikraft^|nanos^|osv^|rumprun^|mirageos] [--vmm=^<vmm^>] [--cloud-boot=uefi-gpt^|none] [--allow-stub-sdk] [app_dir] [output_elf]
exit /b 0

:: ## flags_done
:: Validates inputs, checks idempotency stamp, and builds or wraps the unikernel artifact.
:flags_done
set "FRAMEWORK=!FRAMEWORK:unikernel-=!"
set "APP_DIR=%~1"
if "!APP_DIR!"=="" set "APP_DIR=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
set "OUT_ELF=%~2"
if "!OUT_ELF!"=="" set "OUT_ELF=!LIBSCRIPT_ROOT_DIR!\build\images\unikernel\app.unikernel.elf"
set "STAMP_FILE=!OUT_ELF!.stamp"

if exist "!STAMP_FILE!" if exist "!OUT_ELF!" (
    echo [SKIP] Unikernel image already synthesized: !OUT_ELF!
    exit /b 0
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
    if /i "!CLOUD_BOOT!"=="uefi-gpt" call :wrap_uefi_gpt
    (
        echo mode=stub
        echo framework=!FRAMEWORK!
        echo vmm=!VMM!
        echo cloud_boot=!CLOUD_BOOT!
    ) > "!STAMP_FILE!"
    echo [WARN] !FRAMEWORK! SDK not on host; emitted unikernel descriptor and stub: !OUT_ELF!
    exit /b 0
)

call "!LIBSCRIPT_ROOT_DIR!\_lib\orchestration\vm_builder.cmd" "!LIBSCRIPT_ROOT_DIR!\cli\commands\package_as\unikernel.sh" --framework=!FRAMEWORK! --vmm=!VMM! --cloud-boot=!CLOUD_BOOT! "!APP_DIR!" "!OUT_ELF!"
exit /b !ERRORLEVEL!

:: ## wrap_uefi_gpt
:: Emits UEFI/GPT bootable cloud wrapper metadata and EFI boot stub layout.
:wrap_uefi_gpt
if not exist "!APP_DIR!\boot\efi\EFI\BOOT" mkdir "!APP_DIR!\boot\efi\EFI\BOOT"
copy /y "!OUT_ELF!" "!APP_DIR!\boot\efi\EFI\BOOT\BOOTX64.EFI" >nul 2>&1
(
    echo {"boot_mode":"uefi-gpt","partition_table":"gpt","efi_binary":"/EFI/BOOT/BOOTX64.EFI","framework":"!FRAMEWORK!","vmm":"!VMM!"}
) > "!OUT_ELF!.uefi-gpt.json"
exit /b 0
