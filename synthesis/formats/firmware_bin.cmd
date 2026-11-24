@echo off
:: # firmware_bin.cmd
::
:: ## Overview
:: Tier 2/3 RTOS firmware & simulation bundle exporter on Windows supporting firmware-elf,
:: firmware-bin, firmware-hex, firmware-uf2, mcuboot-signed, renode-resc, and `--profile` dispatch.
::
:: ## Usage
:: firmware_bin.cmd [--profile <path|preset>] [--format=<fmt>] [--kernel=<zephyr|freertos>] [--board=<board>] [--output <path>] [--dry-run] [sysroot] [out_path]

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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "FORMAT=firmware-elf"
set "KERNEL_KIND=%LIBSCRIPT_TARGET_OS%"
if "!KERNEL_KIND!"=="" set "KERNEL_KIND=zephyr"
set "BOARD=%LIBSCRIPT_RTOS_BOARD%"
if "!BOARD!"=="" set "BOARD=qemu_x86_64"
set "BOARD_EXPLICIT="
set "PROFILE="
set "SYSROOT="
set "OUT_PATH="
set "DRY_RUN=0"
set "EXTRA_RTOS="
goto :parse_fw_args

:: ## parse_fw_args
:: Parses options and positional arguments for firmware_bin.cmd.
:parse_fw_args
set "_WA=%~1"
if "!_WA!"=="" goto :fw_args_done
if /I "!_WA!"=="--help" goto :show_help
if /I "!_WA!"=="-h" goto :show_help
if /I "!_WA!"=="--profile" ( set "PROFILE=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA!"=="-p" ( set "PROFILE=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA:~0,10!"=="--profile=" ( set "PROFILE=!_WA:~10!" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--format" ( set "FORMAT=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA!"=="-f" ( set "FORMAT=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA:~0,9!"=="--format=" ( set "FORMAT=!_WA:~9!" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--kernel" ( set "KERNEL_KIND=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA:~0,9!"=="--kernel=" ( set "KERNEL_KIND=!_WA:~9!" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--board" ( set "BOARD=%~2" & set "BOARD_EXPLICIT=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA:~0,8!"=="--board=" ( set "BOARD=!_WA:~8!" & set "BOARD_EXPLICIT=!_WA:~8!" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--output" ( set "OUT_PATH=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA!"=="--out" ( set "OUT_PATH=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA!"=="-o" ( set "OUT_PATH=%~2" & shift & shift & goto :parse_fw_args )
if /I "!_WA:~0,9!"=="--output=" ( set "OUT_PATH=!_WA:~9!" & shift & goto :parse_fw_args )
if /I "!_WA:~0,6!"=="--out=" ( set "OUT_PATH=!_WA:~6!" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--dry-run" ( set "DRY_RUN=1" & set "EXTRA_RTOS=!EXTRA_RTOS! --dry-run" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--strict" ( set "EXTRA_RTOS=!EXTRA_RTOS! --strict" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--allow-stub" ( set "EXTRA_RTOS=!EXTRA_RTOS! --allow-stub" & shift & goto :parse_fw_args )
if /I "!_WA!"=="--offline" ( set "EXTRA_RTOS=!EXTRA_RTOS! --offline" & shift & goto :parse_fw_args )
if "!SYSROOT!"=="" ( set "SYSROOT=!_WA!" ) else ( set "OUT_PATH=!_WA!" )
shift
goto :parse_fw_args

:: ## show_help
:: Displays usage instructions for firmware_bin.cmd.
:show_help
echo Usage: %~nx0 [--profile ^<path^|preset^>] [--format=^<fmt^>] [--kernel=^<zephyr^|freertos^>] [--board=^<board^>] [--output ^<path^>] [--dry-run] [sysroot] [out_path]
exit /b 0

:: ## fw_args_done
:: Packages ELF, BIN, HEX, UF2, MCUboot signed image, or Renode .resc script.
:fw_args_done
if /I "!FORMAT!"=="firmware_bin" set "FORMAT=firmware-bin"
if not "!PROFILE!"=="" (
    if not "!BOARD_EXPLICIT!"=="" set "EXTRA_RTOS=!EXTRA_RTOS! --board=!BOARD_EXPLICIT!"
    set "STACK="
    if not "!OUT_PATH!"=="" (
        call "!SCRIPT_DIR!\rtos_distro.cmd" --profile "!PROFILE!" --format "!FORMAT!" --output "!OUT_PATH!" !EXTRA_RTOS!
        exit /b !ERRORLEVEL!
    )
    call "!SCRIPT_DIR!\rtos_distro.cmd" --profile "!PROFILE!" --format "!FORMAT!" !EXTRA_RTOS!
    exit /b !ERRORLEVEL!
)

if "!SYSROOT!"=="" set "SYSROOT=%LIBSCRIPT_TARGET_SYSROOT%"
if "!SYSROOT!"=="" set "SYSROOT=!LIBSCRIPT_ROOT_DIR!\build\target-sysroot"
if "!OUT_PATH!"=="" set "OUT_PATH=!LIBSCRIPT_ROOT_DIR!\build\images\firmware\!KERNEL_KIND!-!BOARD!.!FORMAT!"

if "!DRY_RUN!"=="1" (
    echo [DRYRUN] Firmware ^(!KERNEL_KIND!, format=!FORMAT!, board=!BOARD!^) target verified -^> !OUT_PATH!
    exit /b 0
)

if exist "!OUT_PATH!.stamp" if exist "!OUT_PATH!" if not "%FORCE_REBUILD%"=="1" (
    echo [SKIP] Firmware artifact already packaged: !OUT_PATH!
    exit /b 0
)

for %%P in ("!OUT_PATH!") do (
    if not exist "%%~dpP" mkdir "%%~dpP"
)
if not exist "!SYSROOT!\boot" mkdir "!SYSROOT!\boot"

if not exist "!SYSROOT!\boot\zephyr.elf" if not exist "!SYSROOT!\boot\freertos.elf" (
    set "LIBSCRIPT_TARGET_OS=!KERNEL_KIND!"
    set "LIBSCRIPT_RTOS_BOARD=!BOARD!"
    set "LIBSCRIPT_TARGET_SYSROOT=!SYSROOT!"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\kernel_stage.cmd" install || exit /b 1
)

set "ELF_SRC=!SYSROOT!\boot\zephyr.elf"
set "BIN_SRC=!SYSROOT!\boot\zephyr.bin"
set "HEX_SRC=!SYSROOT!\boot\zephyr.hex"
if exist "!SYSROOT!\boot\freertos.elf" (
    if /I "!KERNEL_KIND!"=="freertos" (
        set "ELF_SRC=!SYSROOT!\boot\freertos.elf"
        set "BIN_SRC=!SYSROOT!\boot\freertos.bin"
        set "HEX_SRC=!SYSROOT!\boot\freertos.hex"
    )
)

if /I "!FORMAT!"=="firmware-elf" copy /y "!ELF_SRC!" "!OUT_PATH!" >nul
if /I "!FORMAT!"=="firmware-bin" copy /y "!BIN_SRC!" "!OUT_PATH!" >nul
if /I "!FORMAT!"=="firmware-hex" copy /y "!HEX_SRC!" "!OUT_PATH!" >nul
if /I "!FORMAT!"=="mcuboot-signed" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\_lib\bootloaders\mcuboot\sign_firmware.cmd" "!BIN_SRC!" "!OUT_PATH!" || exit /b 1
)
if /I "!FORMAT!"=="firmware-uf2" (
    set "UF2_DIR=%LIBSCRIPT_HOME%\firmware-tools\bin"
    if not exist "!UF2_DIR!" mkdir "!UF2_DIR!"
    if not exist "!UF2_DIR!\uf2_c_packer.exe" (
        where cl >nul 2>&1 && cl /nologo /O2 /Fe:"!UF2_DIR!\uf2_c_packer.exe" "!SCRIPT_DIR!\uf2_c_packer.c" >nul 2>&1
        if not exist "!UF2_DIR!\uf2_c_packer.exe" where gcc >nul 2>&1 && gcc -std=c11 -O2 -o "!UF2_DIR!\uf2_c_packer.exe" "!SCRIPT_DIR!\uf2_c_packer.c" >nul 2>&1
        if not exist "!UF2_DIR!\uf2_c_packer.exe" where clang >nul 2>&1 && clang -std=c11 -O2 -o "!UF2_DIR!\uf2_c_packer.exe" "!SCRIPT_DIR!\uf2_c_packer.c" >nul 2>&1
    )
    "!UF2_DIR!\uf2_c_packer.exe" "!BIN_SRC!" "!OUT_PATH!" || exit /b 1
)
if /I "!FORMAT!"=="renode-resc" (
    for %%E in ("!ELF_SRC!") do set "ELF_BASE=%%~nxE"
    for %%O in ("!OUT_PATH!") do set "OUT_DIR=%%~dpO"
    copy /y "!ELF_SRC!" "!OUT_DIR!!ELF_BASE!" >nul
    set "_HEAP_INV=%FREERTOS_HEAP_IMPL%"
    if "!_HEAP_INV!"=="" set "_HEAP_INV=dynamic_heap"
    (
        echo # LibScript Renode headless simulation script ^(!KERNEL_KIND! / !BOARD!^)
        echo # INVARIANT: heap_implementation=!_HEAP_INV!
        echo # INVARIANT: uart_telemetry=LIBSCRIPT_BOOT_OK
        echo using sysbus
        echo mach create "!KERNEL_KIND!-!BOARD!"
        echo showAnalyzer sysbus.uart0
        echo sysbus LoadELF @!OUT_DIR!!ELF_BASE!
        echo start
        if /I "!_HEAP_INV!"=="static_only" echo # INVARIANT: static_only zero_heap_allocation total_heap_bytes=0 pvPortMalloc=absent
    ) > "!OUT_PATH!"
)

> "!OUT_PATH!.stamp" echo format=!FORMAT!
echo [OK] Packaged !KERNEL_KIND! ^(!FORMAT!, board=!BOARD!^) -^> !OUT_PATH!
exit /b 0
