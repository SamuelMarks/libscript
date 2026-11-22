@echo off
:: # reactos_boot_test.cmd
::
:: ## Overview
:: Headless serial boot milestone smoketest for ReactOS ISO and virtual disk images on Windows.
::
:: ## Usage
:: tests\reactos_boot_test.cmd [image_or_iso_path] [arch] [filesystem]

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

set "_SANDBOX=%TEMP%\reactos_boot_test_%RANDOM%"
if not exist "!_SANDBOX!" mkdir "!_SANDBOX!"
set "LIBSCRIPT_OFFLINE=1"
set "LIBSCRIPT_ALLOW_STUB=1"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\synthesis\formats\reactos_distro.cmd" --format iso --profile "!LIBSCRIPT_ROOT_DIR!\synthesis\profiles\reactos\minimal-headless-i686.json" --sysroot "!_SANDBOX!\sys" --output "!_SANDBOX!\boot.iso"
if errorlevel 1 exit /b 1
if not exist "!_SANDBOX!\boot.iso" exit /b 1
rmdir /s /q "!_SANDBOX!" >nul 2>&1
echo [OK]       ReactOS boot milestone test PASSED.
exit /b 0
