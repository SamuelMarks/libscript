@echo off
:: # test_phase7_linux_uki_matrix.cmd
:: ## Overview
:: Windows companion verification suite for Phase 7 multi-compiler Linux kernel profiles,
:: Secure Boot UKI (.efi) synthesis, multi-arch cross-compilation, and initramfs compression flags.
:: ## Usage
:: tests\test_phase7_linux_uki_matrix.cmd

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
set "TMP_P7=%TEMP%\libscript_p7_%RANDOM%_%RANDOM%"
if not exist "!TMP_P7!" mkdir "!TMP_P7!"

echo [TEST 1/4] Verifying 5-compiler Linux kernel profiles on Windows...
for %%P in (linux-kernel-gcc-tiny linux-kernel-clang-tiny linux-kernel-tcc-tiny linux-kernel-edgcpp-tiny linux-kernel-custom-cc-tiny) do (
    set "STACK="
    call "!LS_CMD!" package-as linux-kernel --profile %%P --output "!TMP_P7!\dk-%%P" --allow-stub
    if errorlevel 1 goto :fail
    if not exist "!TMP_P7!\dk-%%P\boot-manifest.json" goto :fail
)

echo [TEST 2/4] Verifying UKI ^(.efi^) Secure Boot synthesis and 2x idempotency...
set "STACK="
call "!LS_CMD!" package-as linux-kernel --profile linux-kernel-gcc-tiny --format uki --output "!TMP_P7!\uki\linux-x86_64.efi" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P7!\uki\linux-x86_64.efi" goto :fail
set "STACK="
call "!LS_CMD!" package-as linux-kernel --profile linux-kernel-gcc-tiny --format uki --output "!TMP_P7!\uki\linux-x86_64.efi" --allow-stub > "!TMP_P7!\uki_2nd.log" 2>&1
findstr /I /C:"[SKIP]" "!TMP_P7!\uki_2nd.log" >nul 2>&1
if errorlevel 1 goto :fail

echo [TEST 3/4] Verifying multi-arch ^(aarch64, riscv64, i686^) direct-kernel and UKI synthesis...
for %%A in (aarch64 riscv64 i686) do (
    set "STACK="
    call "!LS_CMD!" package-as linux-distro --profile linux-minimal-headless-musl --arch %%A --format direct-kernel --output "!TMP_P7!\ma-%%A" --allow-stub
    if errorlevel 1 goto :fail
    findstr /I /C:"\"arch\":\"%%A\"" "!TMP_P7!\ma-%%A\boot-manifest.json" >nul 2>&1
    if errorlevel 1 goto :fail
    set "STACK="
    call "!LS_CMD!" package-as linux-distro --profile linux-minimal-headless-musl --arch %%A --format uki --output "!TMP_P7!\ma-%%A.efi" --allow-stub
    if errorlevel 1 goto :fail
)

echo [TEST 4/4] Verifying initramfs zstd vs lz4 compression stamps...
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\initramfs\gen_initramfs.cmd" --compress=zstd "!TMP_P7!\init_zstd"
if errorlevel 1 goto :fail
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\initramfs\gen_initramfs.cmd" --compress=lz4 "!TMP_P7!\init_lz4"
if errorlevel 1 goto :fail

rmdir /s /q "!TMP_P7!" 2>nul
echo [PASS] All Phase 7 Windows Linux/UKI/multi-arch tests succeeded.
exit /b 0

:: ## fail
:: Cleans up temporary artifacts and exits 1 on failure.
:fail
echo [FAIL] Phase 7 Windows test suite failed. >&2
if exist "!TMP_P7!" rmdir /s /q "!TMP_P7!" 2>nul
exit /b 1
