@echo off
:: # test_dos_kernel_synthesis.cmd
::
:: ## Overview
:: End-to-end Plane B verification suite on Windows for FreeDOS 1.4 and MIT MS-DOS 1.25/2.0/4.00 synthesis.
::
:: ## Usage
:: tests\test_dos_kernel_synthesis.cmd

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

set "WORK=%TEMP%\dos_synth_e2e_!RANDOM!"
if not exist "!WORK!\trait_sys" mkdir "!WORK!\trait_sys"
set "SOURCE_DATE_EPOCH=1700000000"

set "TARGET_OS=msdos"
set "LIBSCRIPT_DOS_STRATUM=dos32-dpmi"
set "LIBSCRIPT_TARGET_SYSROOT=!WORK!\trait_sys"
for %%T in (logging maintenance backup) do (
    set "STACK="
    call "!LIBSCRIPT_ROOT_DIR!\traits\engine.cmd" apply %%T >nul
    if errorlevel 1 exit /b 1
)
if not exist "!WORK!\trait_sys\ETC\TRAITS\LOGGING.BAT" exit /b 1
if not exist "!WORK!\trait_sys\ETC\TRAITS\MAINTENA.BAT" exit /b 1
if not exist "!WORK!\trait_sys\ETC\TRAITS\BACKUP.BAT" exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\traits\engine.cmd" apply firewall --strict >nul 2>&1
if not "!errorlevel!"=="86" exit /b 1

set "LIBSCRIPT_TARGET_OS=freedos"
set "LIBSCRIPT_DOS_VERSION=1.4"
set "LIBSCRIPT_DOS_STRATUM=dos32-dpmi"
set "LIBSCRIPT_DOS_SHELL_PROVIDER=win-cmd-asm"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\dos\assemble.cmd" "!WORK!\sys_fd14" "!WORK!\freedos14.raw"
if errorlevel 1 exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\dos\assemble.cmd" "!WORK!\sys_fd14" "!WORK!\freedos14_2.raw"
if errorlevel 1 exit /b 1
fc /b "!WORK!\freedos14.raw" "!WORK!\freedos14_2.raw" >nul || exit /b 1

set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_DOS_VERSION=4.0"
set "LIBSCRIPT_DOS_STRATUM=dos32-dpmi"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\dos\assemble.cmd" "!WORK!\sys_ms40" "!WORK!\msdos40.raw"
if errorlevel 1 exit /b 1

set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_DOS_VERSION=2.0"
set "LIBSCRIPT_DOS_STRATUM=dos16-handle"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\dos\assemble.cmd" "!WORK!\sys_ms20" "!WORK!\msdos20.img"
if errorlevel 1 exit /b 1

set "LIBSCRIPT_TARGET_OS=msdos"
set "LIBSCRIPT_DOS_VERSION=1.25"
set "LIBSCRIPT_DOS_STRATUM=dos16-fcb"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\distro\dos\assemble.cmd" "!WORK!\sys_ms125" "!WORK!\msdos125.img"
if errorlevel 1 exit /b 1

rmdir /s /q "!WORK!"
echo [PASS] End-to-end DOS base-kernel synthesis verified on Windows.
exit /b 0
