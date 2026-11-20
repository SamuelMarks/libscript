@echo off
:: # freertos_boot_test.cmd
::
:: ## Overview
:: Headless FreeRTOS boot & scheduler verification suite on Windows (Win32 simulator + QEMU).
::
:: ## Usage
:: tests\freertos_boot_test.cmd

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

set "TMP_FR=%TEMP%\libscript_frboot_%RANDOM%"
if not exist "!TMP_FR!" mkdir "!TMP_FR!"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\freertos\build_firmware.cmd" "--board=win32_sim" "--sysroot=!TMP_FR!\sim" || exit /b 1
"!TMP_FR!\sim\boot\freertos.elf" > "!TMP_FR!\sim.log" 2>&1
findstr /C:"LIBSCRIPT_FREERTOS_BOOT_OK" "!TMP_FR!\sim.log" >nul 2>&1 || (
    echo [FAIL] Missing LIBSCRIPT_FREERTOS_BOOT_OK on Windows FreeRTOS sim >&2
    rmdir /s /q "!TMP_FR!" 2>nul
    exit /b 1
)
rmdir /s /q "!TMP_FR!" 2>nul
echo [PASS] FreeRTOS Windows simulator boot test succeeded^^!
exit /b 0
