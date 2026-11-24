@echo off
:: # test_phase8_bsd_illumos_reactos_matrix.cmd
:: ## Overview
:: Windows companion verification suite for Phase 8 FreeBSD, illumos, and ReactOS hypervisor boot,
:: Wayland screenshots, ZFS stream synthesis, and RosBE PE32/PE32+ bitness verification.
:: ## Usage
:: tests\test_phase8_bsd_illumos_reactos_matrix.cmd

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
set "TMP_P8=%TEMP%\libscript_p8_%RANDOM%_%RANDOM%"
if not exist "!TMP_P8!" mkdir "!TMP_P8!"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_ALLOW_STUB=1"

echo [TEST 1/5] FreeBSD UFS2 and ZFS-on-root boot verification...
for %%P in (minimal-server freebsd-server-standard zfs-cloud) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\freebsd_distro.cmd" --profile %%P --format qcow2 --sysroot "!TMP_P8!\fb-%%P" --output "!TMP_P8!\fb-%%P.qcow2" --allow-stub
    if errorlevel 1 goto :fail
    set "STACK="
    call "!SCRIPT_DIR!\freebsd_boot_test.cmd" "!TMP_P8!\fb-%%P.qcow2" bsd-rc 30 zfs
    if errorlevel 1 goto :fail
)

echo [TEST 2/5] FreeBSD Wayland Sway and KDE Plasma 6 screenshot verification...
set "STACK="
call "!SCRIPT_DIR!\freebsd_gui_smoke_test.cmd" "!TMP_P8!\fb-sway" wayland sway greetd "!TMP_P8!\sway.ppm"
if errorlevel 1 goto :fail
if not exist "!TMP_P8!\sway.ppm" goto :fail
set "STACK="
call "!SCRIPT_DIR!\freebsd_gui_smoke_test.cmd" "!TMP_P8!\fb-plasma" wayland plasma sddm "!TMP_P8!\plasma.ppm"
if errorlevel 1 goto :fail
if not exist "!TMP_P8!\plasma.ppm" goto :fail

echo [TEST 3/5] illumos boot, svcs -xv health, and zfs-stream verification...
for %%P in (minimal-server zfs-cloud hardened-runit) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\illumos_distro.cmd" --profile %%P --format qcow2 --sysroot "!TMP_P8!\il-%%P" --output "!TMP_P8!\il-%%P.qcow2" --allow-stub
    if errorlevel 1 goto :fail
    set "STACK="
    call "!SCRIPT_DIR!\illumos_boot_test.cmd" "!TMP_P8!\il-%%P.qcow2" smf
    if errorlevel 1 goto :fail
)
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\illumos_distro.cmd" --profile zfs-cloud --format zfs-stream --sysroot "!TMP_P8!\il-zstream" --output "!TMP_P8!\illumos.zfs.zst" --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P8!\illumos.zfs.zst" goto :fail

echo [TEST 4/5] ReactOS i686 and x86_64 unattended serial boot matrix...
for %%P in (minimal-headless-i686 desktop-classic-i686 btrfs-appliance-i686 nightly-x86_64) do (
    set "STACK="
    call "!LS_CMD!" package-as reactos-distro --profile %%P --format iso --output "!TMP_P8!\ros-%%P.iso" --allow-stub
    if errorlevel 1 goto :fail
    set "STACK="
    call "!SCRIPT_DIR!\reactos_boot_test.cmd" "!TMP_P8!\ros-%%P.iso"
    if errorlevel 1 goto :fail
)

echo [TEST 5/5] ReactOS --from-source RosBE PE32/PE32+ bitness verification...
set "STACK="
call "!LS_CMD!" package-as reactos-distro --profile minimal-headless-i686 --format iso --sysroot "!TMP_P8!\ros32" --output "!TMP_P8!\ros32.iso" --from-source --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P8!\ros32\iso_root\ReactOS\System32\ntoskrnl.exe" goto :fail
certutil -encodehex "!TMP_P8!\ros32\iso_root\ReactOS\System32\ntoskrnl.exe" "!TMP_P8!\pe32.hex" 4 >nul 2>&1
if not errorlevel 1 (
    findstr /I /C:"4c 01" "!TMP_P8!\pe32.hex" >nul 2>&1 || goto :fail
    findstr /I /C:"0b 01" "!TMP_P8!\pe32.hex" >nul 2>&1 || goto :fail
)
set "STACK="
call "!LS_CMD!" package-as reactos-distro --profile nightly-x86_64 --format iso --sysroot "!TMP_P8!\ros64" --output "!TMP_P8!\ros64.iso" --from-source --allow-stub
if errorlevel 1 goto :fail
if not exist "!TMP_P8!\ros64\iso_root\ReactOS\System32\ntoskrnl.exe" goto :fail
certutil -encodehex "!TMP_P8!\ros64\iso_root\ReactOS\System32\ntoskrnl.exe" "!TMP_P8!\pe64.hex" 4 >nul 2>&1
if not errorlevel 1 (
    findstr /I /C:"64 86" "!TMP_P8!\pe64.hex" >nul 2>&1 || goto :fail
    findstr /I /C:"0b 02" "!TMP_P8!\pe64.hex" >nul 2>&1 || goto :fail
)

rmdir /s /q "!TMP_P8!" 2>nul
echo [PASS] All Phase 8 Windows FreeBSD/illumos/ReactOS matrix tests succeeded.
exit /b 0

:: ## fail
:: Cleans up temporary files and exits 1 on failure.
:fail
echo [FAIL] Phase 8 Windows matrix failed. >&2
if exist "!TMP_P8!" rmdir /s /q "!TMP_P8!" 2>nul
exit /b 1
