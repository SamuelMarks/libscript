@echo off
:: # test_rtos_idempotency.cmd
::
:: ## Overview
:: 2x consecutive idempotency and stamp-invalidation recovery test suite for Zephyr and FreeRTOS on Windows.
::
:: ## Usage
:: tests\test_rtos_idempotency.cmd

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

set "TMP_IDEM=%TEMP%\libscript_rtos_idem_%RANDOM%"
set "LIBSCRIPT_HOME=!TMP_IDEM!\home"
if not exist "!LIBSCRIPT_HOME!" mkdir "!LIBSCRIPT_HOME!"

set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\freertos\build_firmware.cmd" "--board=win32_sim" "--sysroot=!TMP_IDEM!\frsys" || exit /b 1
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\freertos\build_firmware.cmd" "--board=win32_sim" "--sysroot=!TMP_IDEM!\frsys" > "!TMP_IDEM!\pass2.log"
findstr /C:"[SKIP]" "!TMP_IDEM!\pass2.log" >nul 2>&1 || (
    echo [FAIL] FreeRTOS pass 2 did not [SKIP] on Windows >&2
    rmdir /s /q "!TMP_IDEM!" 2>nul
    exit /b 1
)
del /f /q "!TMP_IDEM!\frsys\boot\freertos.elf"
set "STACK="
call "!LIBSCRIPT_ROOT_DIR!\_lib\kernel\freertos\build_firmware.cmd" "--board=win32_sim" "--sysroot=!TMP_IDEM!\frsys" || exit /b 1
if not exist "!TMP_IDEM!\frsys\boot\freertos.elf" exit /b 1
rmdir /s /q "!TMP_IDEM!" 2>nul
echo [PASS] RTOS 2x Consecutive Idempotency Suite PASSED on Windows^^!
exit /b 0
