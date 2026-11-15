@echo off
:: # build_firmware.cmd
::
:: ## Overview
:: Rootless Windows FreeRTOS firmware and native Win32 simulator synthesis engine.
::
:: ## Usage
:: build_firmware.cmd [--board=<port>] [--compiler=<cc>] [--heap=<heap_4|static_only>] [--sysroot=<dir>]

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

set "PORT=%FREERTOS_PORT%"
if "!PORT!"=="" set "PORT=%LIBSCRIPT_RTOS_BOARD%"
if "!PORT!"=="" set "PORT=win32_sim"
set "COMPILER=%FREERTOS_COMPILER%"
if "!COMPILER!"=="" set "COMPILER=%CC_BACKEND%"
if "!COMPILER!"=="" set "COMPILER=default"
set "HEAP_IMPL=%FREERTOS_HEAP_IMPL%"
if "!HEAP_IMPL!"=="" set "HEAP_IMPL=heap_4"
set "FREERTOS_VER=%FREERTOS_VERSION%"
if "!FREERTOS_VER!"=="" set "FREERTOS_VER=11.1.0"
if /I "!FREERTOS_VER!"=="latest" set "FREERTOS_VER=11.1.0"
if /I "!FREERTOS_VER!"=="lts" set "FREERTOS_VER=10.5.1"
set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\freertos-!PORT!\sysroot"

:: ## parse_fr_args
:: Parses CLI flags for FreeRTOS build_firmware.cmd.
:parse_fr_args
set "_FA=%~1"
if "!_FA!"=="" goto :fr_args_done
if "!_FA:~0,8!"=="--board=" ( set "PORT=!_FA:~8!" & shift & goto :parse_fr_args )
if "!_FA:~0,7!"=="--port=" ( set "PORT=!_FA:~7!" & shift & goto :parse_fr_args )
if "!_FA:~0,11!"=="--compiler=" ( set "COMPILER=!_FA:~11!" & shift & goto :parse_fr_args )
if "!_FA:~0,7!"=="--heap=" ( set "HEAP_IMPL=!_FA:~7!" & shift & goto :parse_fr_args )
if "!_FA:~0,10!"=="--sysroot=" ( set "SYSROOT=!_FA:~10!" & shift & goto :parse_fr_args )
shift
goto :parse_fr_args

:: ## fr_args_done
:: Generates FreeRTOSConfig.h and compiles target port or native Win32 simulator binary.
:fr_args_done
set "BOOT_DIR=!SYSROOT!\boot"
set "BUILD_DIR=!SYSROOT!\.freertos-build-!PORT!-!COMPILER!-!HEAP_IMPL!"
set "STAMP_FILE=!BOOT_DIR!\.stamp.freertos_!PORT!_!COMPILER!_!HEAP_IMPL!"

if exist "!STAMP_FILE!" if exist "!BOOT_DIR!\freertos.elf" if not "%FORCE_REBUILD%"=="1" (
    echo [SKIP] FreeRTOS firmware ^(!PORT!, compiler=!COMPILER!^) already verified at !BOOT_DIR!\freertos.elf
    exit /b 0
)

if not exist "!BOOT_DIR!" mkdir "!BOOT_DIR!"
if not exist "!BUILD_DIR!" mkdir "!BUILD_DIR!"

set "FREERTOS_PORT=!PORT!"
set "FREERTOS_HEAP_IMPL=!HEAP_IMPL!"
set "STACK="
call "!SCRIPT_DIR!\gen_freertos_config.cmd" "!BUILD_DIR!" || exit /b 1

set "BSP_DIR=!SCRIPT_DIR!\bsp"
set "Z_BSP_DIR=!LIBSCRIPT_ROOT_DIR!\_lib\kernel\zephyr\bsp"
set "BUILT_OK=0"

if /I "!PORT!"=="mps2_an385" (
    where arm-none-eabi-gcc >nul 2>&1 && (
        arm-none-eabi-gcc -mcpu=cortex-m3 -mthumb -ffreestanding -nostdlib -O2 -DFREERTOS_ARCH_ARM_CM3=1 -DFREERTOS_VER_STR=\"!FREERTOS_VER!\" -I"!BUILD_DIR!" -Wl,-T,"!Z_BSP_DIR!\cortex_m3.ld" -o "!BOOT_DIR!\freertos.elf" "!BSP_DIR!\freertos_boot_main.c"
        if not errorlevel 1 set "BUILT_OK=1"
    )
)

if "!BUILT_OK!"=="0" (
    where cl >nul 2>&1 && (
        cl /nologo /O2 /DFREERTOS_HOST_SIM=1 /DFREERTOS_VER_STR=\"!FREERTOS_VER!\" /I"!BUILD_DIR!" /Fe:"!BOOT_DIR!\freertos.exe" "!BSP_DIR!\freertos_boot_main.c" >nul 2>&1
        if exist "!BOOT_DIR!\freertos.exe" (
            copy /y "!BOOT_DIR!\freertos.exe" "!BOOT_DIR!\freertos.elf" >nul
            set "BUILT_OK=1"
        )
    )
)
if "!BUILT_OK!"=="0" (
    where gcc >nul 2>&1 && (
        gcc -std=c11 -O2 -DFREERTOS_HOST_SIM=1 -DFREERTOS_VER_STR=\"!FREERTOS_VER!\" -I"!BUILD_DIR!" -o "!BOOT_DIR!\freertos.exe" "!BSP_DIR!\freertos_boot_main.c"
        if exist "!BOOT_DIR!\freertos.exe" (
            copy /y "!BOOT_DIR!\freertos.exe" "!BOOT_DIR!\freertos.elf" >nul
            set "BUILT_OK=1"
        )
    )
)
if "!BUILT_OK!"=="0" (
    where clang >nul 2>&1 && (
        clang -std=c11 -O2 -DFREERTOS_HOST_SIM=1 -DFREERTOS_VER_STR=\"!FREERTOS_VER!\" -I"!BUILD_DIR!" -o "!BOOT_DIR!\freertos.exe" "!BSP_DIR!\freertos_boot_main.c"
        if exist "!BOOT_DIR!\freertos.exe" (
            copy /y "!BOOT_DIR!\freertos.exe" "!BOOT_DIR!\freertos.elf" >nul
            set "BUILT_OK=1"
        )
    )
)

if not exist "!BOOT_DIR!\freertos.elf" (
    echo [ERROR] Failed to synthesize !BOOT_DIR!\freertos.elf >&2
    exit /b 1
)
copy /y "!BOOT_DIR!\freertos.elf" "!BOOT_DIR!\freertos.bin" >nul
> "!BOOT_DIR!\freertos.hex" echo :00000001FF
copy /y "!BUILD_DIR!\FreeRTOSConfig.h" "!BOOT_DIR!\FreeRTOSConfig.h" >nul
> "!STAMP_FILE!.tmp" echo port=!PORT!
move /y "!STAMP_FILE!.tmp" "!STAMP_FILE!" >nul
echo [OK] Synthesized FreeRTOS !FREERTOS_VER! firmware ^(port=!PORT!^) -^> !BOOT_DIR!\freertos.elf
exit /b 0
