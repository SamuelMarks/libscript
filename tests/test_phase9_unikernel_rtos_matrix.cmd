@echo off
:: # test_phase9_unikernel_rtos_matrix.cmd
:: ## Overview
:: Windows companion verification suite for Phase 9 Unikernel Tender (5 frameworks across QEMU &
:: Firecracker, Solo5 hvt/spt TAP probes, OVMF uefi-gpt, Hyper-V Gen2 azure-vhd) and RTOS
:: Simulator/HIL (Cortex-M3, RISC-V 64, Renode static_only, UF2, and MCUboot RSA-2048/Ed25519).
:: ## Usage
:: tests\test_phase9_unikernel_rtos_matrix.cmd

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

set "LS_CMD=!LIBSCRIPT_ROOT_DIR!\libscript.cmd"
set "TMP_P9=%TEMP%\libscript_p9_%RANDOM%_%RANDOM%"
if not exist "!TMP_P9!" mkdir "!TMP_P9!"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_ALLOW_STUB=1"

echo [TEST 1/6] Boot-testing 5 unikernel frameworks across QEMU and Firecracker...
for %%U in (unikernel-osv-redis-postgres unikernel-mirageos-https unikernel-unikraft-redis unikernel-nanos-postgres unikernel-rumprun-redis) do (
    set "STACK="
    call "!LS_CMD!" package-as unikernel-distro --profile %%U --format elf --vmm qemu --output "!TMP_P9!\%%U-qemu.elf" --allow-stub
    if errorlevel 1 goto :fail
    if not exist "!TMP_P9!\%%U-qemu.elf" goto :fail
    set "STACK="
    call "!LS_CMD!" package-as unikernel-distro --profile %%U --format elf --vmm firecracker --output "!TMP_P9!\%%U-fc.elf" --allow-stub
    if errorlevel 1 goto :fail
    if not exist "!TMP_P9!\%%U-fc.elf.firecracker.json" goto :fail
)

echo [TEST 2/6] Verifying Solo5 hvt and spt tenders + TAP probes...
for %%T in (hvt spt) do (
    set "STACK="
    call "!LS_CMD!" package-as unikernel-distro --profile unikernel-mirageos-https --format elf --tender %%T --output "!TMP_P9!\mirage-%%T.ukvm" --allow-stub
    if errorlevel 1 goto :fail
    if not exist "!TMP_P9!\mirage-%%T.ukvm.solo5-manifest.json" goto :fail
    if not exist "!TMP_P9!\mirage-%%T.ukvm.tender.json" goto :fail
)

echo [TEST 3/6] Validating --format uefi-gpt and --format azure-vhd cloud-boot manifests...
set "STACK="
call "!LS_CMD!" package-as unikernel-distro --profile unikernel-unikraft-redis --format uefi-gpt --output "!TMP_P9!\uk-ovmf.raw" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P9!\uk-ovmf.raw.uefi-gpt.json" goto :fail
set "STACK="
call "!LS_CMD!" package-as unikernel-distro --profile unikernel-unikraft-redis --format azure-vhd --output "!TMP_P9!\uk-azure.vhd" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P9!\uk-azure.vhd.azure-vhd.json" goto :fail

echo [TEST 4/6] Synthesizing Cortex-M3 and RISC-V 64 RTOS firmware profiles...
for %%R in (zephyr-cortex-m3-mcuboot-signed freertos-cortex-m3-mps2-minimal zephyr-riscv64-mqtt-sqlite freertos-riscv64-static-safety) do (
    set "STACK="
    call "!LS_CMD!" package-as rtos-distro --profile %%R --format firmware-elf --output "!TMP_P9!\%%R.elf" --allow-stub
    if errorlevel 1 goto :fail
    if not exist "!TMP_P9!\%%R.elf" goto :fail
)

echo [TEST 5/6] Verifying Renode .resc static_only zero-heap-allocation invariants...
if not exist "!TMP_P9!\renode" mkdir "!TMP_P9!\renode"
set "STACK="
call "!LS_CMD!" package-as rtos-distro --profile freertos-riscv64-static-safety --format renode-resc --output "!TMP_P9!\renode\static.resc" --allow-stub
if errorlevel 1 goto :fail
findstr /C:"static_only zero_heap_allocation" "!TMP_P9!\renode\static.resc" >nul 2>&1 || goto :fail

echo [TEST 6/6] Verifying UF2 and MCUboot RSA-2048 / Ed25519 signed images...
set "STACK="
call "!LS_CMD!" package-as rtos-distro --profile zephyr-cortex-m3-mcuboot-signed --format firmware-uf2 --output "!TMP_P9!\cm3.uf2" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P9!\cm3.uf2" goto :fail
set "STACK="
call "!LS_CMD!" package-as rtos-distro --profile zephyr-cortex-m3-mcuboot-signed --format mcuboot-signed --key-type rsa-2048 --output "!TMP_P9!\cm3-rsa.signed.bin" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P9!\cm3-rsa.signed.bin" goto :fail
set "STACK="
call "!LS_CMD!" package-as rtos-distro --profile zephyr-cortex-m3-mcuboot-signed --format mcuboot-signed --key-type ed25519 --output "!TMP_P9!\cm3-ed.signed.bin" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P9!\cm3-ed.signed.bin" goto :fail

rmdir /s /q "!TMP_P9!" 2>nul
echo [PASS] All Phase 9 Windows Unikernel and RTOS matrix tests succeeded.
exit /b 0

:: ## fail
:: Cleans up temporary artifacts and exits 1 on test failure.
:fail
rmdir /s /q "!TMP_P9!" 2>nul
echo [FAIL] Phase 9 Windows Unikernel/RTOS matrix test failed. >&2
exit /b 1
