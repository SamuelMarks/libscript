@echo off
:: # test_qemu_msdos_smoke.cmd
:: ## Overview
:: Headless QEMU FreeDOS / MS-DOS 4.0 (`dos32`) smoke test and Phase 5 substrate verification on Windows.
:: Verifies `LIBSCRIPT_DOS_83=1` (`C:\LIBSCRIP`, `FBSDUBIN`, `SQLITETL`, `WINCMDRS`), `WATTCP.CFG`
:: online/offline synthesis, and boots a synthesized 1.44 MiB DOS32A smoke floppy in `qemu-system-i386` when present.
:: ## Usage
:: call tests\test_qemu_msdos_smoke.cmd

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

set "TEST_WORK=%TEMP%\ls_qemu_dos_%RANDOM%_%RANDOM%"
if not exist "!TEST_WORK!\DL\jq" mkdir "!TEST_WORK!\DL\jq" 2>nul
if not exist "!TEST_WORK!\DL\freebsd-usr-bin" mkdir "!TEST_WORK!\DL\freebsd-usr-bin" 2>nul

:: 1. Verify default LIBSCRIPT_HOME=C:\LIBSCRIP resolution and 8.3 lookup table
set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_DOS_83=1"
set "LIBSCRIPT_HOME="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos_83.cmd" :libscript_dos83_home >nul
if /i not "!DOS83_HOME!"=="C:\LIBSCRIP" (
    echo [FAIL] Expected default MS-DOS LIBSCRIPT_HOME C:\LIBSCRIP, got !DOS83_HOME! 1>&2
    goto :fail_cleanup
)
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos_83.cmd" :libscript_dos83_comp "freebsd-usr-bin" >nul
if not "!DOS83_COMP!"=="FBSDUBIN" (
    echo [FAIL] Expected FBSDUBIN for freebsd-usr-bin, got !DOS83_COMP! 1>&2
    goto :fail_cleanup
)
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos_83.cmd" :libscript_dos83_comp "sqlite-tools" >nul
if not "!DOS83_COMP!"=="SQLITETL" (
    echo [FAIL] Expected SQLITETL for sqlite-tools, got !DOS83_COMP! 1>&2
    goto :fail_cleanup
)

:: 2. Stage jq.exe + sed.exe in strict 8.3 mode
set "DOS_HOME=!TEST_WORK!\LIBSCRIP"
> "!TEST_WORK!\DL\jq\jq-1.8.2-dos32.exe" echo LE-DOS32-JQ-1.8.2
> "!TEST_WORK!\DL\DOS32A.EXE" echo MZ-DOS32A-9.12

set "LIBSCRIPT_HOME=!DOS_HOME!"
set "LIBSCRIPT_OFFLINE=1"
set "DOWNLOAD_DIR=!TEST_WORK!\DL"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\libscript.cmd" depends jq
if errorlevel 1 goto :fail_cleanup

if not exist "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" (
    echo [FAIL] Expected strict 8.3 path !DOS_HOME!\JQ\1_8_2\bin\jq.exe 1>&2
    goto :fail_cleanup
)
if not exist "!DOS_HOME!\JQ\ACTIVE.VER" (
    echo [FAIL] Expected !DOS_HOME!\JQ\ACTIVE.VER pointer in 8.3 mode 1>&2
    goto :fail_cleanup
)

:: 3. Verify Watt-32 WATTCP.CFG online vs offline generation
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_HOME=!TEST_WORK!\OFFNET"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\wattcp_cfg.cmd" >nul
if exist "!TEST_WORK!\OFFNET\ETC\WATTCP.CFG" (
    echo [FAIL] WATTCP.CFG must not be generated when LIBSCRIPT_OFFLINE=1 1>&2
    goto :fail_cleanup
)

set "LIBSCRIPT_OFFLINE=0"
set "LIBSCRIPT_HOME=!TEST_WORK!\ONNET"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\wattcp_cfg.cmd" >nul
if not exist "!TEST_WORK!\ONNET\ETC\WATTCP.CFG" (
    echo [FAIL] Expected !TEST_WORK!\ONNET\ETC\WATTCP.CFG in online MS-DOS mode 1>&2
    goto :fail_cleanup
)
findstr /C:"my_ip = dhcp" "!TEST_WORK!\ONNET\ETC\WATTCP.CFG" >nul || goto :fail_cleanup

:: 4. Optional C89 helper + headless QEMU boot when C compiler and qemu-system-i386 exist on Windows
set "DOS32_HELPER_BIN="
set "LIBSCRIPT_HOME=!TEST_WORK!\HELPERS"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\_common\dos32\build_dos32.cmd" ls-mkdos-smoke >nul 2>&1
if not "!DOS32_HELPER_BIN!"=="" if exist "!DOS32_HELPER_BIN!" (
    "!DOS32_HELPER_BIN!" "!TEST_WORK!\DOS32SMK.IMG" "!TEST_WORK!\DL\DOS32A.EXE" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "WIN_HOST_SMOKE"
    if errorlevel 1 goto :fail_cleanup
    where qemu-system-i386.exe >nul 2>&1
    if not errorlevel 1 (
        qemu-system-i386.exe -M pc -m 16M -display none -no-reboot -device isa-debug-exit,iobase=0xf4,iosize=0x04 -boot a -drive "file=!TEST_WORK!\DOS32SMK.IMG,format=raw,if=floppy" -serial "file:!TEST_WORK!\com1.log" >nul 2>&1
        findstr /C:"[PASS] QEMU_DOS32A_SMOKE" "!TEST_WORK!\com1.log" >nul || goto :fail_cleanup
    )
)

rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [PASS] MS-DOS 8.3, Watt-32, and QEMU DOS32A smoke checks succeeded.
exit /b 0

:: ## fail_cleanup
:: Removes temporary test artifacts and exits with status 1.
:fail_cleanup
if exist "!TEST_WORK!" rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [FAIL] MS-DOS smoke test failed. 1>&2
exit /b 1
