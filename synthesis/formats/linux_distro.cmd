@echo off
:: # linux_distro.cmd
::
:: ## Overview
:: Unified CLI entrypoint to synthesize and package a Linux kernel or distribution profile on Windows.
::
:: ## Usage
:: synthesis\formats\linux_distro.cmd --format <qcow2|raw|iso|vmdk|vdi|vhd|box|rootfs-tar|direct-kernel> --profile <path> [--output <path>] [--dry-run] [--allow-stub] [--strict] [--offline]

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

set "FORMAT=%LIBSCRIPT_LINUX_DEFAULT_FORMAT%"
if "!FORMAT!"=="" set "FORMAT=qcow2"
set "PROFILE=%LIBSCRIPT_LINUX_DEFAULT_PROFILE%"
if "!PROFILE!"=="" set "PROFILE=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\linux\linux-minimal-headless-musl.json"
set "OUTPUT="
set "CLI_ARCH="
set "INITRAMFS_COMPRESS=%LIBSCRIPT_INITRAMFS_COMPRESS%"
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
set "STRICT_BUILD=0"
if "%LIBSCRIPT_STRICT_IMAGE_BUILD%"=="1" set "STRICT_BUILD=1"
set "OFFLINE_MODE=0"
if "%LIBSCRIPT_OFFLINE%"=="1" set "OFFLINE_MODE=1"
goto :parse_args

:: ## parse_args
:: Parses CLI options for linux_distro.cmd.
:parse_args
if "%~1"=="" goto :args_done
set "_ARG=%~1"
if /I "!_ARG!"=="--help" goto :show_help
if /I "!_ARG!"=="-h" goto :show_help
if /I "!_ARG!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,9!"=="--format=" ( set "FORMAT=!_ARG:~9!" & shift & goto :parse_args )
if /I "!_ARG!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,10!"=="--profile=" ( set "PROFILE=!_ARG:~10!" & shift & goto :parse_args )
if /I "!_ARG!"=="--arch" ( set "CLI_ARCH=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,7!"=="--arch=" ( set "CLI_ARCH=!_ARG:~7!" & shift & goto :parse_args )
if /I "!_ARG!"=="--initramfs-compress" ( set "INITRAMFS_COMPRESS=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,21!"=="--initramfs-compress=" ( set "INITRAMFS_COMPRESS=!_ARG:~21!" & shift & goto :parse_args )
if /I "!_ARG!"=="--key" ( set "LIBSCRIPT_UKI_KEY=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,6!"=="--key=" ( set "LIBSCRIPT_UKI_KEY=!_ARG:~6!" & shift & goto :parse_args )
if /I "!_ARG!"=="--cert" ( set "LIBSCRIPT_UKI_CERT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,7!"=="--cert=" ( set "LIBSCRIPT_UKI_CERT=!_ARG:~7!" & shift & goto :parse_args )
if /I "!_ARG!"=="--cmdline" ( set "LIBSCRIPT_UKI_CMDLINE=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,10!"=="--cmdline=" ( set "LIBSCRIPT_UKI_CMDLINE=!_ARG:~10!" & shift & goto :parse_args )
if /I "!_ARG!"=="--output" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="--out" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG!"=="-o" ( set "OUTPUT=%~2" & shift & shift & goto :parse_args )
if /I "!_ARG:~0,9!"=="--output=" ( set "OUTPUT=!_ARG:~9!" & shift & goto :parse_args )
if /I "!_ARG:~0,6!"=="--out=" ( set "OUTPUT=!_ARG:~6!" & shift & goto :parse_args )
if /I "!_ARG!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_args )
if /I "!_ARG!"=="--strict" ( set "STRICT_BUILD=1" & set "ALLOW_STUB=0" & shift & goto :parse_args )
if /I "!_ARG!"=="--allow-stub" ( set "ALLOW_STUB=1" & set "STRICT_BUILD=0" & shift & goto :parse_args )
if /I "!_ARG!"=="--offline" ( set "OFFLINE_MODE=1" & shift & goto :parse_args )
echo [ERROR] Unknown argument: !_ARG! >&2
exit /b 1

:: ## args_done
:: Resolves Linux profile path, checks idempotency stamp, and dispatches synthesis.
:args_done
set "_P_NORM=!PROFILE:/=\!"
if not exist "!_P_NORM!" (
    if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_P_NORM!.json" set "_P_NORM=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\!_P_NORM!.json"
)
if not exist "!_P_NORM!" (
    if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\linux\!_P_NORM!.json" set "_P_NORM=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\linux\!_P_NORM!.json"
)
if not exist "!_P_NORM!" (
    if exist "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\lfs\!_P_NORM!.json" set "_P_NORM=!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\lfs\!_P_NORM!.json"
)
set "PROFILE=!_P_NORM!"
if not exist "!PROFILE!" (
    echo [ERROR] Linux profile not found: !PROFILE! >&2
    exit /b 1
)

for %%F in ("!PROFILE!") do set "PNAME=%%~nF"
set "KERNEL_ARG=linux-glibc"
findstr /I /C:"linux-musl" /C:"\"musl\"" "!PROFILE!" >nul 2>&1
if not errorlevel 1 set "KERNEL_ARG=linux-musl"

set "EFF_ARCH=x86_64"
if not "!CLI_ARCH!"=="" set "EFF_ARCH=!CLI_ARCH!"
set "ARCH_SFX="
if not "!CLI_ARCH!"=="" set "ARCH_SFX=-!CLI_ARCH!"
if not "!INITRAMFS_COMPRESS!"=="" set "LIBSCRIPT_INITRAMFS_COMPRESS=!INITRAMFS_COMPRESS!"

set "SYNTH_FMT=!FORMAT!"
if /I "!FORMAT!"=="qcow2" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\qemu\linux-!PNAME!!ARCH_SFX!.qcow2"
    set "SYNTH_FMT=qcow2"
    goto :dispatch_ready
)
if /I "!FORMAT!"=="raw" goto :fmt_raw
if /I "!FORMAT!"=="raw-img" goto :fmt_raw
if /I "!FORMAT!"=="iso" goto :fmt_iso
if /I "!FORMAT!"=="live-iso" goto :fmt_iso
if /I "!FORMAT!"=="vmdk" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\vmware\linux-!PNAME!!ARCH_SFX!.vmdk"
    set "SYNTH_FMT=vmdk"
    goto :dispatch_ready
)
if /I "!FORMAT!"=="vdi" (
    if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\virtualbox\linux-!PNAME!!ARCH_SFX!.vdi"
    set "SYNTH_FMT=vdi"
    goto :dispatch_ready
)
if /I "!FORMAT!"=="vhd" goto :fmt_vhd
if /I "!FORMAT!"=="vhdx" goto :fmt_vhd
if /I "!FORMAT!"=="box" goto :fmt_box
if /I "!FORMAT!"=="vagrant-box" goto :fmt_box
if /I "!FORMAT!"=="rootfs-tar" goto :fmt_rootfs
if /I "!FORMAT!"=="oci-image" goto :fmt_rootfs
if /I "!FORMAT!"=="uki" goto :fmt_uki
if /I "!FORMAT!"=="direct-kernel" goto :fmt_dk
if /I "!FORMAT!"=="kernel" goto :fmt_dk
echo [ERROR] Unsupported Linux packaging format: !FORMAT! >&2
exit /b 1

:: ## fmt_raw
:: Configures raw image output defaults.
:fmt_raw
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\raw\linux-!PNAME!!ARCH_SFX!.raw"
set "SYNTH_FMT=raw"
goto :dispatch_ready

:: ## fmt_iso
:: Configures live ISO output defaults.
:fmt_iso
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\iso\linux-!PNAME!!ARCH_SFX!.iso"
set "SYNTH_FMT=iso"
goto :dispatch_ready

:: ## fmt_vhd
:: Configures Hyper-V VHD output defaults.
:fmt_vhd
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\hyperv\linux-!PNAME!!ARCH_SFX!.vhd"
set "SYNTH_FMT=vhd"
goto :dispatch_ready

:: ## fmt_box
:: Configures Vagrant box output defaults.
:fmt_box
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\vagrant\linux-!PNAME!!ARCH_SFX!.box"
set "SYNTH_FMT=vagrant-box"
goto :dispatch_ready

:: ## fmt_rootfs
:: Configures rootfs archive output defaults.
:fmt_rootfs
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\rootfs\linux-!PNAME!!ARCH_SFX!.rootfs.tar.gz"
set "SYNTH_FMT=rootfs-tar"
goto :dispatch_ready

:: ## fmt_uki
:: Configures Unified Kernel Image (.efi) output defaults.
:fmt_uki
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\uki\linux-!PNAME!-!EFF_ARCH!.efi"
set "SYNTH_FMT=uki"
goto :dispatch_ready

:: ## fmt_dk
:: Configures direct-kernel bundle output defaults.
:fmt_dk
if "!OUTPUT!"=="" set "OUTPUT=!LIBSCRIPT_ROOT_DIR!\build\images\direct-kernel\linux-!PNAME!!ARCH_SFX!"
set "SYNTH_FMT=direct-kernel"
goto :dispatch_ready

:: ## dispatch_ready
:: Executes dry-run validation or full Linux artifact synthesis with stamp idempotency.
:dispatch_ready
set "ARCH_OPT="
if not "!CLI_ARCH!"=="" set "ARCH_OPT=--arch=!CLI_ARCH!"
if "!DRY_RUN!"=="1" (
    echo [DISTRO]   Validating Linux ^(!KERNEL_ARG!, arch=!EFF_ARCH!^) synthesis plan from !PROFILE! ^(format=!FORMAT!^)...
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=!KERNEL_ARG!" "--profile=!PROFILE!" "--format=!SYNTH_FMT!" "--out=!OUTPUT!" !ARCH_OPT! --dry-run
    exit /b !ERRORLEVEL!
)

set "STAMP_FILE=!OUTPUT!.stamp"
if exist "!STAMP_FILE!" (
    if exist "!OUTPUT!" (
        findstr /I /C:"format=!FORMAT!" "!STAMP_FILE!" >nul 2>&1
        if not errorlevel 1 (
            findstr /I /C:"arch=!EFF_ARCH!" "!STAMP_FILE!" >nul 2>&1
            if not errorlevel 1 (
                echo [SKIP]     Linux distribution artifact already synthesized: !OUTPUT!
                exit /b 0
            )
        )
    )
)

for %%D in ("!OUTPUT!") do if not exist "%%~dpD" mkdir "%%~dpD"
if "!ALLOW_STUB!"=="1" set "LIBSCRIPT_ALLOW_STUB=1"
if "!STRICT_BUILD!"=="1" set "LIBSCRIPT_STRICT_IMAGE_BUILD=1"
if "!OFFLINE_MODE!"=="1" set "LIBSCRIPT_OFFLINE=1"

echo [DISTRO]   Synthesizing Linux ^(!KERNEL_ARG!, arch=!EFF_ARCH!^) artifact from !PROFILE!...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\synthesize-image.cmd" "--kernel=!KERNEL_ARG!" "--profile=!PROFILE!" "--format=!SYNTH_FMT!" "--out=!OUTPUT!" !ARCH_OPT!
if errorlevel 1 exit /b !ERRORLEVEL!

(
    echo format=!FORMAT!
    echo kernel=!KERNEL_ARG!
    echo arch=!EFF_ARCH!
    echo profile=!PROFILE!
) > "!STAMP_FILE!"

echo [OK]       Linux distribution packaged as !FORMAT!: !OUTPUT!
exit /b 0

:: ## show_help
:: Displays usage instructions for linux_distro.cmd.
:show_help
echo Usage: %~nx0 [--format ^<qcow2^|raw^|iso^|vmdk^|vdi^|vhd^|box^|rootfs-tar^|direct-kernel^|uki^>] [--profile ^<path^|preset^>] [--arch ^<arch^>] [--output ^<path^>] [--dry-run] [--allow-stub] [--strict] [--offline]
exit /b 0
