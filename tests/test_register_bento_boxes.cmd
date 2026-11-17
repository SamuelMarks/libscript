@echo off
:: # test_register_bento_boxes.cmd
::
:: ## Overview
:: Unit and 2x-idempotency test suite for tests\register_bento_boxes.cmd on Windows, verifying
:: host-arch-aware DOS .box discovery (msdos-{1.25,2.0,4.0}, freedos-{1.3,1.4}), canonical bento/*
:: plus legacy anondos/* registration, and --validate-only template checks.
::
:: ## Usage
:: call tests\test_register_bento_boxes.cmd

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

set "TEST_WORK=%TEMP%\ls_reg_bento_%RANDOM%_%RANDOM%"
set "MOCK_BENTO=!TEST_WORK!\bento"
set "MOCK_BIN=!TEST_WORK!\bin"
set "MOCK_VAG_HOME=!TEST_WORK!\vagrant_home"
set "MOCK_STATE=!TEST_WORK!\vagrant_boxes.txt"
set "MOCK_ADDS=!TEST_WORK!\vagrant_adds.log"

for %%D in (
    "!MOCK_BIN!"
    "!MOCK_VAG_HOME!\boxes"
    "!MOCK_BENTO!\builds\build_complete"
    "!MOCK_BENTO!\os_pkrvars\omnios"
    "!MOCK_BENTO!\os_pkrvars\alpine"
    "!MOCK_BENTO!\os_pkrvars\debian"
    "!MOCK_BENTO!\os_pkrvars\rockylinux"
    "!MOCK_BENTO!\os_pkrvars\freebsd"
    "!MOCK_BENTO!\os_pkrvars\macos"
    "!MOCK_BENTO!\os_pkrvars\windows"
    "!MOCK_BENTO!\os_pkrvars\freedos"
    "!MOCK_BENTO!\os_pkrvars\msdos"
) do (
    if not exist "%%~D" mkdir "%%~D"
)

type nul > "!MOCK_STATE!"
type nul > "!MOCK_ADDS!"

for %%A in (aarch64 x86_64) do (
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\alpine\alpine-3.24-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\debian\debian-13-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\rockylinux\rockylinux-10-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\freebsd\freebsd-15-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\windows\windows-11-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\freedos\freedos-1.3-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\freedos\freedos-1.4-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\msdos\msdos-1.25-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\msdos\msdos-2.0-%%A.pkrvars.hcl"
    echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\msdos\msdos-4.0-%%A.pkrvars.hcl"
)
echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\omnios\omnios-braich-aarch64.pkrvars.hcl"
echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\macos\macos-14-aarch64.pkrvars.hcl"
echo # pkrvars> "!MOCK_BENTO!\os_pkrvars\macos\macos-27-aarch64.pkrvars.hcl"
for %%B in (freedos-builder.sh freedos-builder.cmd msdos-builder.sh msdos-builder.cmd) do (
    echo # builder> "!MOCK_BENTO!\%%B"
)
for %%X in (msdos-1.25-aarch64.qemu.box msdos-2.0-aarch64.qemu.box msdos-4.0-x86_64.qemu.box freedos-1.3-aarch64.qemu.box) do (
    echo MOCK-BOX> "!MOCK_BENTO!\builds\build_complete\%%X"
)

(
    echo @echo off
    echo setlocal EnableDelayedExpansion
    echo if /i "%%~1"=="box" if /i "%%~2"=="list" ^(
    echo     type "!MOCK_STATE!"
    echo     exit /b 0
    echo ^)
    echo if /i "%%~1"=="box" if /i "%%~2"=="add" ^(
    echo     shift
    echo     shift
    echo     set "_N="
    echo     set "_P=qemu"
    echo     set "_F="
    echo     :vag_loop
    echo     if "%%~1"=="" goto :vag_done
    echo     if /i "%%~1"=="--name" ^( set "_N=%%~2" ^& shift ^& shift ^& goto :vag_loop ^)
    echo     if /i "%%~1"=="--provider" ^( set "_P=%%~2" ^& shift ^& shift ^& goto :vag_loop ^)
    echo     if /i "%%~1"=="--force" ^( shift ^& goto :vag_loop ^)
    echo     set "_F=%%~1"
    echo     shift
    echo     goto :vag_loop
    echo     :vag_done
    echo     echo !_N! ^(!_P!, 0^)>> "!MOCK_STATE!"
    echo     echo !_N!^|!_P!^|!_F!>> "!MOCK_ADDS!"
    echo     exit /b 0
    echo ^)
    echo exit /b 0
) > "!MOCK_BIN!\vagrant.cmd"

set "ORIG_PATH=!PATH!"
set "PATH=!MOCK_BIN!;!PATH!"
set "VAGRANT_HOME=!MOCK_VAG_HOME!"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd" --bento-dir "!MOCK_BENTO!" --arch aarch64 --validate-only > "!TEST_WORK!\val.log" 2>&1
if errorlevel 1 goto :fail_cleanup
findstr /C:"os_pkrvars\freedos\freedos-1.3-aarch64.pkrvars.hcl" "!TEST_WORK!\val.log" >nul || goto :fail_cleanup
findstr /C:"os_pkrvars\msdos\msdos-4.0-aarch64.pkrvars.hcl" "!TEST_WORK!\val.log" >nul || goto :fail_cleanup

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd" --bento-dir "!MOCK_BENTO!" --arch aarch64 > "!TEST_WORK!\run1.log" 2>&1
if errorlevel 1 goto :fail_cleanup

for %%E in ("bento/msdos-1.25|qemu" "bento/msdos-2.0|qemu" "bento/msdos-4.0|qemu" "bento/freedos-1.3|qemu" "bento/freedos|qemu" "anondos/msdos-4.0|qemu" "anondos/freedos-1.4|qemu") do (
    findstr /C:%%E "!MOCK_ADDS!" >nul || goto :fail_cleanup
)

for /f %%C in ('find /c /v "" ^< "!MOCK_ADDS!"') do set "COUNT1=%%C"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\tests\register_bento_boxes.cmd" --bento-dir "!MOCK_BENTO!" --arch aarch64 > "!TEST_WORK!\run2.log" 2>&1
if errorlevel 1 goto :fail_cleanup

for /f %%C in ('find /c /v "" ^< "!MOCK_ADDS!"') do set "COUNT2=%%C"
if not "!COUNT1!"=="!COUNT2!" goto :fail_cleanup
findstr /C:"[OK]   Box bento/msdos-4.0 (qemu) is already registered" "!TEST_WORK!\run2.log" >nul || goto :fail_cleanup

set "PATH=!ORIG_PATH!"
if exist "!TEST_WORK!" rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [PASS] register_bento_boxes.cmd DOS discovery, cross-arch fallback, and 2x idempotency tests passed.
exit /b 0

:: ## fail_cleanup
:: Cleans up temporary mock directories and exits with status 1 on failure.
:fail_cleanup
set "PATH=!ORIG_PATH!"
if exist "!TEST_WORK!" rmdir /s /q "!TEST_WORK!" >nul 2>&1
echo [FAIL] register_bento_boxes.cmd test failed. 1>&2
exit /b 1
