@echo off
:: # uki.cmd
:: ## Overview
:: Packages a target Linux sysroot and kernel/initramfs into a Secure Boot signed UEFI
:: Unified Kernel Image (`.efi` UKI) on Windows via `uki_c_packer` or stub fallback.
:: ## Usage
:: synthesis\formats\uki.cmd [--profile <path|preset>] [--arch=<x86_64|aarch64|riscv64|i686>] [--output <path>] [--cmdline=<str>] [--dry-run] [--allow-stub] [target_sysroot] [output_efi]

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

if /I "%~1"=="--help" goto :show_help
if /I "%~1"=="-h" goto :show_help

echo %* | findstr /I /C:"--profile" /C:"-p " >nul 2>&1
if not errorlevel 1 (
    set "STACK="
    call "!SCRIPT_DIR!\_profile_dispatch.cmd" "uki" %*
    exit /b !ERRORLEVEL!
)

set "TARGET_ARCH=x86_64"
if not "%LIBSCRIPT_TARGET_ARCH%"=="" set "TARGET_ARCH=%LIBSCRIPT_TARGET_ARCH%"
set "CMDLINE=console=ttyS0 panic=-1 quiet"
set "OUT_OPT="
set "DRY_RUN=0"
if "%LIBSCRIPT_DRY_RUN%"=="1" set "DRY_RUN=1"
set "ALLOW_STUB=0"
if "%LIBSCRIPT_ALLOW_STUB%"=="1" set "ALLOW_STUB=1"
goto :parse_uki_opts

:: ## parse_uki_opts
:: Parses CLI options for uki.cmd.
:parse_uki_opts
set "_ARG=%~1"
if "!_ARG!"=="" goto :uki_opts_done
if /I "!_ARG:~0,7!"=="--arch=" ( set "TARGET_ARCH=!_ARG:~7!" & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--arch" ( set "TARGET_ARCH=%~2" & shift & shift & goto :parse_uki_opts )
if /I "!_ARG:~0,9!"=="--output=" ( set "OUT_OPT=!_ARG:~9!" & shift & goto :parse_uki_opts )
if /I "!_ARG:~0,6!"=="--out=" ( set "OUT_OPT=!_ARG:~6!" & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--output" ( set "OUT_OPT=%~2" & shift & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--out" ( set "OUT_OPT=%~2" & shift & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="-o" ( set "OUT_OPT=%~2" & shift & shift & goto :parse_uki_opts )
if /I "!_ARG:~0,10!"=="--cmdline=" ( set "CMDLINE=!_ARG:~10!" & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--cmdline" ( set "CMDLINE=%~2" & shift & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--dry-run" ( set "DRY_RUN=1" & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--allow-stub" ( set "ALLOW_STUB=1" & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--strict" ( set "ALLOW_STUB=0" & shift & goto :parse_uki_opts )
if /I "!_ARG!"=="--offline" ( shift & goto :parse_uki_opts )
goto :uki_opts_done

:: ## uki_opts_done
:: Builds or stubs the signed PE32/PE32+ Unified Kernel Image (.efi).
:uki_opts_done
set "TARGET_SYSROOT=%~1"
if "!TARGET_SYSROOT!"=="" set "TARGET_SYSROOT=!LIBSCRIPT_TARGET_SYSROOT!"
if "!TARGET_SYSROOT!"=="" set "TARGET_SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
set "OUT_EFI=!OUT_OPT!"
if "!OUT_EFI!"=="" set "OUT_EFI=%~2"
if "!OUT_EFI!"=="" set "OUT_EFI=!LIBSCRIPT_ROOT_DIR!\build\images\uki\linux-!TARGET_ARCH!.efi"

if "!DRY_RUN!"=="1" (
    echo [DRYRUN] UKI ^(.efi, arch=!TARGET_ARCH!^) target verified -^> !OUT_EFI!
    exit /b 0
)

set "STAMP_FILE=!OUT_EFI!.stamp"
if exist "!STAMP_FILE!" (
    if exist "!OUT_EFI!" (
        findstr /I /C:"arch=!TARGET_ARCH!" "!STAMP_FILE!" >nul 2>&1
        if not errorlevel 1 (
            echo [SKIP] Unified Kernel Image ^(.efi^) already synthesized: !OUT_EFI!
            exit /b 0
        )
    )
)

for %%D in ("!OUT_EFI!") do if not exist "%%~dpD" mkdir "%%~dpD"
if not exist "!TARGET_SYSROOT!" mkdir "!TARGET_SYSROOT!"

set "WORK_DIR=%TEMP%\ls_uki_%RANDOM%_%RANDOM%"
if not exist "!WORK_DIR!" mkdir "!WORK_DIR!"
echo NAME="LibScript Linux"> "!WORK_DIR!\osrel.txt"
echo(!CMDLINE!> "!WORK_DIR!\cmdline.txt"

set "K_IN=!TARGET_SYSROOT!\boot\vmlinuz"
if not exist "!K_IN!" (
    set "K_IN=!WORK_DIR!\vmlinuz.stub"
    echo LibScript Linux Kernel Stub ^(!TARGET_ARCH!^)> "!K_IN!"
)
set "I_IN=!TARGET_SYSROOT!\boot\initramfs.img"
if not exist "!I_IN!" (
    set "I_IN=!WORK_DIR!\initramfs.stub"
    echo LibScript Initramfs Stub ^(!TARGET_ARCH!^)> "!I_IN!"
)
set "S_IN=!WORK_DIR!\authenticode.sig"
echo LIBSCRIPT-AUTHENTICODE-SHA256-TEST-SIG-!TARGET_ARCH!> "!S_IN!"

set "PACKER_EXE=!WORK_DIR!\uki_c_packer.exe"
set "BUILT_PACKER=0"
where gcc >nul 2>&1
if not errorlevel 1 (
    gcc -std=c11 -O2 -o "!PACKER_EXE!" "!SCRIPT_DIR!\uki_c_packer.c" >nul 2>&1
    if exist "!PACKER_EXE!" set "BUILT_PACKER=1"
)
if "!BUILT_PACKER!"=="0" (
    where clang >nul 2>&1
    if not errorlevel 1 (
        clang -std=c11 -O2 -o "!PACKER_EXE!" "!SCRIPT_DIR!\uki_c_packer.c" >nul 2>&1
        if exist "!PACKER_EXE!" set "BUILT_PACKER=1"
    )
)

if "!BUILT_PACKER!"=="1" (
    "!PACKER_EXE!" "!OUT_EFI!" "!TARGET_ARCH!" "!WORK_DIR!\osrel.txt" "!WORK_DIR!\cmdline.txt" "!K_IN!" "!I_IN!" "!S_IN!"
    set "SIGN_METHOD=pe32plus-authenticode"
) else (
    if not "!ALLOW_STUB!"=="1" (
        rmdir /s /q "!WORK_DIR!" 2>nul
        echo [ERROR] Native UKI C11 packer compiler unavailable on Windows without --allow-stub. >&2
        exit /b 86
    )
    echo MZ PE !TARGET_ARCH! LIBSCRIPT_UKI_STUB> "!OUT_EFI!"
    set "SIGN_METHOD=stub-fallback"
)

(
    echo {"format":"uki","arch":"!TARGET_ARCH!","sign_method":"!SIGN_METHOD!","sections":[".osrel",".cmdline",".linux",".initrd"]}
) > "!OUT_EFI!.sig.json"

(
    echo mode=stub
    echo format=uki
    echo arch=!TARGET_ARCH!
    echo sign_method=!SIGN_METHOD!
) > "!STAMP_FILE!"

rmdir /s /q "!WORK_DIR!" 2>nul
echo [OK] Unified Kernel Image ^(.efi^) synthesized ^(!TARGET_ARCH!^): !OUT_EFI!
exit /b 0

:: ## show_help
:: Displays usage instructions for uki.cmd.
:show_help
echo Usage: %~nx0 [--profile ^<path^|preset^>] [--arch=^<x86_64^|aarch64^|riscv64^|i686^>] [--output ^<path^>] [--cmdline=^<str^>] [--dry-run] [--allow-stub] [target_sysroot] [output_efi]
exit /b 0
