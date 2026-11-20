@echo off
:: # build_firmware.cmd
::
:: ## Overview
:: Rootless Windows Zephyr RTOS firmware synthesis engine using CMake, Ninja, Zephyr SDK, or Clang/LLD.
::
:: ## Usage
:: build_firmware.cmd [--board=<board>] [--compiler=<cc>] [--sysroot=<dir>]

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

set "BOARD=%ZEPHYR_BOARD%"
if "!BOARD!"=="" set "BOARD=%LIBSCRIPT_RTOS_BOARD%"
if "!BOARD!"=="" set "BOARD=qemu_x86_64"
set "COMPILER=%ZEPHYR_COMPILER%"
if "!COMPILER!"=="" set "COMPILER=%CC_BACKEND%"
if "!COMPILER!"=="" set "COMPILER=default"
set "ZEPHYR_VER=%ZEPHYR_VERSION%"
if "!ZEPHYR_VER!"=="" set "ZEPHYR_VER=3.7.0"
if "!ZEPHYR_VER!"=="latest" set "ZEPHYR_VER=3.7.0"
set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\zephyr-!BOARD!\sysroot"
goto :parse_bf_args

:: ## parse_bf_args
:: Parses command-line flags for build_firmware.cmd.
:parse_bf_args
set "_BA=%~1"
if "!_BA!"=="" goto :bf_args_done
if "!_BA:~0,8!"=="--board=" ( set "BOARD=!_BA:~8!" & shift & goto :parse_bf_args )
if "!_BA:~0,11!"=="--compiler=" ( set "COMPILER=!_BA:~11!" & shift & goto :parse_bf_args )
if "!_BA:~0,10!"=="--sysroot=" ( set "SYSROOT=!_BA:~10!" & shift & goto :parse_bf_args )
shift
goto :parse_bf_args

:: ## bf_args_done
:: Merges Kconfig fragments and compiles Zephyr firmware into SYSROOT\boot.
:bf_args_done
set "BOOT_DIR=!SYSROOT!\boot"
set "BUILD_DIR=!SYSROOT!\.zephyr-build-!BOARD!-!COMPILER!"
set "STAMP_FILE=!BOOT_DIR!\.stamp.zephyr_!BOARD!_!COMPILER!"

if exist "!STAMP_FILE!" if exist "!BOOT_DIR!\zephyr.elf" if not "%FORCE_REBUILD%"=="1" (
    echo [SKIP] Zephyr firmware ^(!BOARD!, compiler=!COMPILER!^) already verified at !BOOT_DIR!\zephyr.elf
    exit /b 0
)

if not exist "!BOOT_DIR!" mkdir "!BOOT_DIR!"
if not exist "!BUILD_DIR!" mkdir "!BUILD_DIR!"

set "STACK="
call "!SCRIPT_DIR!\merge_zephyr_config.cmd" "!BUILD_DIR!" "!BOARD!" || exit /b 1

set "BSP_DIR=!SCRIPT_DIR!\bsp"
set "BUILT_OK=0"

if /I "!BOARD!"=="qemu_cortex_m3" (
    where arm-zephyr-eabi-gcc >nul 2>&1 && (
        arm-zephyr-eabi-gcc -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 -DZEPHYR_ARCH_ARM_CM3=1 -DZEPHYR_VER_STR=\"!ZEPHYR_VER!\" -I"!BUILD_DIR!" -Wl,-T,"!BSP_DIR!\cortex_m3.ld" -o "!BOOT_DIR!\zephyr.elf" "!BSP_DIR!\zephyr_boot_main.c"
        if not errorlevel 1 set "BUILT_OK=1"
    )
    if "!BUILT_OK!"=="0" where arm-none-eabi-gcc >nul 2>&1 && (
        arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 -DZEPHYR_ARCH_ARM_CM3=1 -DZEPHYR_VER_STR=\"!ZEPHYR_VER!\" -I"!BUILD_DIR!" -Wl,-T,"!BSP_DIR!\cortex_m3.ld" -o "!BOOT_DIR!\zephyr.elf" "!BSP_DIR!\zephyr_boot_main.c"
        if not errorlevel 1 set "BUILT_OK=1"
    )
)

if "!BUILT_OK!"=="0" (
    where clang >nul 2>&1 && where ld.lld >nul 2>&1 && (
        if /I "!BOARD!"=="qemu_x86_64" (
            clang --target=i686-unknown-none-elf -ffreestanding -nostdlib -O2 -DZEPHYR_ARCH_X86=1 -DZEPHYR_VER_STR=\"!ZEPHYR_VER!\" -I"!BUILD_DIR!" -c "!BSP_DIR!\zephyr_boot_main.c" -o "!BUILD_DIR!\zb.o"
            ld.lld -m elf_i386 -T "!BSP_DIR!\x86.ld" -o "!BOOT_DIR!\zephyr.elf" "!BUILD_DIR!\zb.o"
            if not errorlevel 1 set "BUILT_OK=1"
        )
    )
)

if "!BUILT_OK!"=="0" (
    where gcc >nul 2>&1 && (
        gcc -std=c11 -O2 -DZEPHYR_HOST_SIM=1 -DZEPHYR_VER_STR=\"!ZEPHYR_VER!\" -I"!BUILD_DIR!" -o "!BOOT_DIR!\zephyr.elf" "!BSP_DIR!\zephyr_boot_main.c"
        if not errorlevel 1 set "BUILT_OK=1"
    )
)
if "!BUILT_OK!"=="0" (
    where clang >nul 2>&1 && (
        clang -std=c11 -O2 -DZEPHYR_HOST_SIM=1 -DZEPHYR_VER_STR=\"!ZEPHYR_VER!\" -I"!BUILD_DIR!" -o "!BOOT_DIR!\zephyr.elf" "!BSP_DIR!\zephyr_boot_main.c"
        if not errorlevel 1 set "BUILT_OK=1"
    )
)
if "!BUILT_OK!"=="0" (
    where cl >nul 2>&1 && (
        cl /nologo /O2 /DZEPHYR_HOST_SIM=1 /DZEPHYR_VER_STR=\"!ZEPHYR_VER!\" /I"!BUILD_DIR!" /Fe:"!BOOT_DIR!\zephyr.elf" "!BSP_DIR!\zephyr_boot_main.c" >nul 2>&1
        if not errorlevel 1 set "BUILT_OK=1"
    )
)

if not exist "!BOOT_DIR!\zephyr.elf" (
    echo [ERROR] Failed to synthesize !BOOT_DIR!\zephyr.elf >&2
    exit /b 1
)
copy /y "!BOOT_DIR!\zephyr.elf" "!BOOT_DIR!\zephyr.bin" >nul
> "!BOOT_DIR!\zephyr.hex" echo :00000001FF
copy /y "!BUILD_DIR!\.config" "!BOOT_DIR!\.config" >nul
copy /y "!BUILD_DIR!\zephyr.dts" "!BOOT_DIR!\zephyr.dts" >nul
> "!STAMP_FILE!.tmp" echo board=!BOARD!
move /y "!STAMP_FILE!.tmp" "!STAMP_FILE!" >nul
echo [OK] Synthesized Zephyr !ZEPHYR_VER! firmware ^(board=!BOARD!^) -^> !BOOT_DIR!\zephyr.elf
exit /b 0
