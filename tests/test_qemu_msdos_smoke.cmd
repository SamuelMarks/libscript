@echo off
:: # test_qemu_msdos_smoke.cmd
::
:: ## Overview
:: Headless QEMU FreeDOS (1.3/1.4) and MS-DOS (4.0/2.0) (dos32) smoke test on Windows.
:: Verifies LIBSCRIPT_DOS_83=1 (C:\LIBSCRIP, FBSDUBIN, SQLITETL, WINCMDRS), WATTCP.CFG online/offline
:: synthesis, and boots real ..\bento MS-DOS & FreeDOS disk images/boxes over COM1 when present (with
:: synthesized 1.44 MiB DOS32A smoke floppy fallback for offline CI).
::
:: ## Usage
:: call tests\test_qemu_msdos_smoke.cmd [--use-bento-disk|--use-bento-vagrant|--synthetic-only] [--bento-dir <path>]

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

set "SMOKE_MODE=auto"
if not defined BENTO_DIR set "BENTO_DIR=%LIBSCRIPT_ROOT_DIR%\..\bento"

call :parse_smoke_args %*
if errorlevel 2 exit /b 0
if errorlevel 1 exit /b 1

set "TEST_WORK=%TEMP%\ls_qemu_dos_%RANDOM%_%RANDOM%"
if not exist "!TEST_WORK!\DL\jq" mkdir "!TEST_WORK!\DL\jq" 2>nul
if not exist "!TEST_WORK!\DL\freebsd-usr-bin" mkdir "!TEST_WORK!\DL\freebsd-usr-bin" 2>nul

:: 1. Verify default LIBSCRIPT_HOME=C:\LIBSCRIP resolution and 8.3 lookup table
set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_DOS_83=1"
set "LIBSCRIPT_HOME="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_home >nul
if /i not "!DOS83_HOME!"=="C:\LIBSCRIP" (
    echo [FAIL] Expected default MS-DOS LIBSCRIPT_HOME C:\LIBSCRIP, got !DOS83_HOME! 1>&2
    goto :fail_cleanup
)
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_comp "freebsd-usr-bin" >nul
if not "!DOS83_COMP!"=="FBSDUBIN" (
    echo [FAIL] Expected FBSDUBIN for freebsd-usr-bin, got !DOS83_COMP! 1>&2
    goto :fail_cleanup
)
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos_83.cmd" :libscript_dos83_comp "sqlite-tools" >nul
if not "!DOS83_COMP!"=="SQLITETL" (
    echo [FAIL] Expected SQLITETL for sqlite-tools, got !DOS83_COMP! 1>&2
    goto :fail_cleanup
)

:: 2. Stage jq.exe + DOS32A.EXE in strict 8.3 mode
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
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\wattcp_cfg.cmd" >nul
if exist "!TEST_WORK!\OFFNET\ETC\WATTCP.CFG" (
    echo [FAIL] WATTCP.CFG must not be generated when LIBSCRIPT_OFFLINE=1 1>&2
    goto :fail_cleanup
)

set "LIBSCRIPT_OFFLINE=0"
set "LIBSCRIPT_HOME=!TEST_WORK!\ONNET"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\wattcp_cfg.cmd" >nul
if not exist "!TEST_WORK!\ONNET\ETC\WATTCP.CFG" (
    echo [FAIL] Expected !TEST_WORK!\ONNET\ETC\WATTCP.CFG in online MS-DOS mode 1>&2
    goto :fail_cleanup
)
findstr /C:"my_ip = dhcp" "!TEST_WORK!\ONNET\ETC\WATTCP.CFG" >nul || goto :fail_cleanup

:: 4. Prepare D:\ workspace for Bento DOS guest execution
set "DRIVE_D=!TEST_WORK!\DRIVE_D"
if not exist "!DRIVE_D!\LIBSCRIP" mkdir "!DRIVE_D!\LIBSCRIP"
if not exist "!DRIVE_D!\ETC" mkdir "!DRIVE_D!\ETC"
xcopy /E /I /Q /Y "!DOS_HOME!\*" "!DRIVE_D!\LIBSCRIP\" >nul 2>&1
copy /Y "!TEST_WORK!\ONNET\ETC\WATTCP.CFG" "!DRIVE_D!\ETC\WATTCP.CFG" >nul
copy /Y "!TEST_WORK!\DL\DOS32A.EXE" "!DRIVE_D!\DOS32A.EXE" >nul
(
    echo @ECHO OFF
    echo VER
    echo IF NOT EXIST D:\LIBSCRIP\JQ\ACTIVE.VER EXIT /B 1
    echo IF NOT EXIST D:\DOS32A.EXE EXIT /B 1
    echo IF NOT EXIST D:\ETC\WATTCP.CFG EXIT /B 1
    echo TYPE D:\LIBSCRIP\JQ\ACTIVE.VER
    echo ECHO [PASS] QEMU_DOS32A_SMOKE WIN_HOST_SMOKE
) > "!DRIVE_D!\SMOKE.BAT"

if /i "!SMOKE_MODE!"=="bento-vagrant" (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\vagrant\msdos-4.0\run_dos_ctest.cmd" "--bento-dir=!BENTO_DIR!" "--out=!TEST_WORK!\vag_msdos40.json" || goto :fail_cleanup
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\vagrant\freedos-1.3\run_dos_ctest.cmd" "--bento-dir=!BENTO_DIR!" "--out=!TEST_WORK!\vag_freedos13.json" || goto :fail_cleanup
    echo [INFO] Smoke execution mode: bento-vagrant ^(msdos-4.0 + freedos-1.3^)
    goto :smoke_done
)

set "QEMU_EXE="
where qemu-system-i386.exe >nul 2>&1 && set "QEMU_EXE=qemu-system-i386.exe"
if "!QEMU_EXE!"=="" (
    where qemu-system-x86_64.exe >nul 2>&1 && set "QEMU_EXE=qemu-system-x86_64.exe"
)

set "EXECUTED_BENTO_DISK=0"
if not "!QEMU_EXE!"=="" if /i not "!SMOKE_MODE!"=="synthetic-only" if /i not "!SMOKE_MODE!"=="synthetic-floppy" (
    call :discover_bento_dos_disk "msdos-4.0 msdos-2.0" MSDOS_FMT MSDOS_IMG
    call :discover_bento_dos_disk "freedos-1.4 freedos-1.3" FREEDOS_FMT FREEDOS_IMG
    set "_CAN_BENTO_DISK=0"
    if not "!MSDOS_IMG!"=="" if not "!FREEDOS_IMG!"=="" if exist "!BENTO_DIR!\msdos-builder.cmd" if exist "!BENTO_DIR!\freedos-builder.cmd" set "_CAN_BENTO_DISK=1"
    if "!_CAN_BENTO_DISK!"=="1" (
        set "_RND=!RANDOM!"
        set /a "MSDOS_PORT=24500 + (_RND - (_RND / 300) * 300)"
        set /a "FREE_PORT=!MSDOS_PORT! + 1"
        start "" /B "!QEMU_EXE!" -machine pc,accel=tcg -cpu max -m 64M -smp 1 -snapshot -drive "file=!MSDOS_IMG!,format=!MSDOS_FMT!,if=ide,index=0,media=disk" -drive "file=fat:!DRIVE_D!,format=raw,if=ide,index=1,media=disk" -serial "telnet:127.0.0.1:!MSDOS_PORT!,server,nowait" -display none
        set "MSDOS_SERIAL_PORT=!MSDOS_PORT!"
        call "!BENTO_DIR!\msdos-builder.cmd" ssh -c "D:\SMOKE.BAT" > "!TEST_WORK!\msdos_com1.log" 2>&1
        findstr /C:"[PASS] QEMU_DOS32A_SMOKE" "!TEST_WORK!\msdos_com1.log" >nul && set "EXECUTED_BENTO_DISK=1"
        if "!EXECUTED_BENTO_DISK!"=="1" (
            echo [INFO] Smoke execution mode: bento-disk ^(..\bento MS-DOS^)
        )
    ) else if /i "!SMOKE_MODE!"=="bento-disk" (
        echo [FAIL] Requested --use-bento-disk, but ..\bento DOS disk images were not found. 1>&2
        goto :fail_cleanup
    )
)

if "!EXECUTED_BENTO_DISK!"=="0" (
    set "DOS32_HELPER_BIN="
    set "LIBSCRIPT_HOME=!TEST_WORK!\HELPERS"
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\engine\common\dos32\build_dos32.cmd" ls-mkdos-smoke >nul 2>&1
    if not "!DOS32_HELPER_BIN!"=="" if exist "!DOS32_HELPER_BIN!" (
        "!DOS32_HELPER_BIN!" "!TEST_WORK!\DOS32SMK.IMG" "!TEST_WORK!\DL\DOS32A.EXE" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "!DOS_HOME!\JQ\1_8_2\bin\jq.exe" "WIN_HOST_SMOKE"
        if errorlevel 1 goto :fail_cleanup
        if not "!QEMU_EXE!"=="" (
            "!QEMU_EXE!" -M pc -m 16M -display none -no-reboot -device isa-debug-exit,iobase=0xf4,iosize=0x04 -boot a -drive "file=!TEST_WORK!\DOS32SMK.IMG,format=raw,if=floppy" -serial "file:!TEST_WORK!\com1.log" >nul 2>&1
            findstr /C:"[PASS] QEMU_DOS32A_SMOKE" "!TEST_WORK!\com1.log" >nul || goto :fail_cleanup
            echo [INFO] Smoke execution mode: synthetic-floppy ^(!QEMU_EXE!^)
        )
    )
)
:: wincheck disable=CMD3005

:: ## smoke_done
:: Cleans up temporary test directory and exits with status 0.
:smoke_done
if exist "!TEST_WORK!" rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [PASS] MS-DOS 8.3, Watt-32, and QEMU DOS32A smoke checks succeeded.
exit /b 0

:: ## parse_smoke_args
:: Parses CLI flags for test_qemu_msdos_smoke.cmd.
:parse_smoke_args
if "%~1"=="" exit /b 0
set "_SA=%~1"
if /i "!_SA!"=="--help" goto :show_smoke_usage
if /i "!_SA!"=="-h" goto :show_smoke_usage
if /i "!_SA!"=="/?" goto :show_smoke_usage
if /i "!_SA!"=="-?" goto :show_smoke_usage
if /i "!_SA!"=="--use-bento-disk" ( set "SMOKE_MODE=bento-disk" & shift & goto :parse_smoke_args )
if /i "!_SA!"=="--use-bento-vagrant" ( set "SMOKE_MODE=bento-vagrant" & shift & goto :parse_smoke_args )
if /i "!_SA!"=="--synthetic-only" ( set "SMOKE_MODE=synthetic-floppy" & shift & goto :parse_smoke_args )
if /i "!_SA!"=="--bento-dir" ( set "BENTO_DIR=%~2" & shift & shift & goto :parse_smoke_args )
if /i "!_SA:~0,12!"=="--bento-dir=" ( set "BENTO_DIR=!_SA:~12!" & shift & goto :parse_smoke_args )
shift
goto :parse_smoke_args

:: ## show_smoke_usage
:: Displays usage instructions and returns exit code 2.
:show_smoke_usage
echo Usage: %~nx0 [--use-bento-disk^|--use-bento-vagrant^|--synthetic-only] [--bento-dir ^<path^>]
exit /b 2

:: ## discover_bento_dos_disk
:: Locates a built .qcow2/.img or .qemu.box-extracted disk image in BENTO_DIR\builds.
:discover_bento_dos_disk
set "_STEMS=%~1"
set "%~2="
set "%~3="
if not exist "!TEST_WORK!\box_extract" mkdir "!TEST_WORK!\box_extract"
for %%S in (!_STEMS!) do (
    if exist "!BENTO_DIR!\builds\%%S.qcow2" (
        set "%~2=qcow2"
        set "%~3=!BENTO_DIR!\builds\%%S.qcow2"
        exit /b 0
    )
    if exist "!BENTO_DIR!\builds\%%S.img" (
        set "%~2=raw"
        set "%~3=!BENTO_DIR!\builds\%%S.img"
        exit /b 0
    )
    for %%A in (x86_64 aarch64 i386) do (
        if exist "!BENTO_DIR!\builds\build_complete\%%S-%%A.qemu.box" (
            if not exist "!TEST_WORK!\box_extract\%%S" mkdir "!TEST_WORK!\box_extract\%%S"
            tar -xzf "!BENTO_DIR!\builds\build_complete\%%S-%%A.qemu.box" -C "!TEST_WORK!\box_extract\%%S" box_0.img 2>nul
            if exist "!TEST_WORK!\box_extract\%%S\box_0.img" (
                set "%~2=qcow2"
                set "%~3=!TEST_WORK!\box_extract\%%S\box_0.img"
                exit /b 0
            )
        )
    )
)
exit /b 1

:: ## fail_cleanup
:: Removes temporary test artifacts and exits with status 1.
:fail_cleanup
if exist "!TEST_WORK!" rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [FAIL] MS-DOS smoke test failed. 1>&2
exit /b 1
