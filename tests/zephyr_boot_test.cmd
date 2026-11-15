@echo off
:: # zephyr_boot_test.cmd
::
:: ## Overview
:: Headless Zephyr RTOS boot verification suite on Windows.
::
:: ## Usage
:: tests\zephyr_boot_test.cmd

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

set "TMP_ZBOOT=%TEMP%\libscript_zboot_%RANDOM%"
if not exist "!TMP_ZBOOT!" mkdir "!TMP_ZBOOT!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\zephyr\build_firmware.cmd" "--board=native_sim" "--sysroot=!TMP_ZBOOT!\sim" || exit /b 1
"!TMP_ZBOOT!\sim\boot\zephyr.elf" > "!TMP_ZBOOT!\sim.log" 2>&1
findstr /C:"LIBSCRIPT_ZEPHYR_BOOT_OK" "!TMP_ZBOOT!\sim.log" >nul 2>&1 || (
    echo [FAIL] Missing LIBSCRIPT_ZEPHYR_BOOT_OK on Windows Zephyr sim >&2
    rmdir /s /q "!TMP_ZBOOT!" 2>nul
    exit /b 1
)
rmdir /s /q "!TMP_ZBOOT!" 2>nul
echo [PASS] Zephyr RTOS Windows boot test succeeded!
exit /b 0
