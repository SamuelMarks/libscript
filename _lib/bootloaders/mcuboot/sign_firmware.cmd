@echo off
:: # sign_firmware.cmd
::
:: ## Overview
:: Cryptographically signs and pads Zephyr or FreeRTOS raw firmware binaries into MCUboot v2 A/B slot images on Windows.
::
:: ## Usage
:: sign_firmware.cmd <in.bin> <out.signed.bin> [--key=<pem>] [--slot-size=0x40000] [--header-size=0x200]

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

if "%LIBSCRIPT_HOME%"=="" set "LIBSCRIPT_HOME=%USERPROFILE%\.libscript"
set "IN_BIN="
set "OUT_BIN="
set "KEY_FILE=%MCUBOOT_KEY_FILE%"
set "KEY_TYPE=%MCUBOOT_KEY_TYPE%"
if "!KEY_TYPE!"=="" set "KEY_TYPE=rsa-2048"
set "SLOT_SIZE=%MCUBOOT_SLOT_SIZE%"
if "!SLOT_SIZE!"=="" set "SLOT_SIZE=0x40000"
set "HEADER_SIZE=%MCUBOOT_HEADER_SIZE%"
if "!HEADER_SIZE!"=="" set "HEADER_SIZE=0x200"
goto :parse_sign_args

:: ## parse_sign_args
:: Parses positional and flag arguments for sign_firmware.cmd.
:parse_sign_args
set "_SA=%~1"
if "!_SA!"=="" goto :args_done
if "!_SA:~0,6!"=="--key=" ( set "KEY_FILE=!_SA:~6!" & shift & goto :parse_sign_args )
if "!_SA:~0,11!"=="--key-type=" ( set "KEY_TYPE=!_SA:~11!" & shift & goto :parse_sign_args )
if "!_SA:~0,12!"=="--slot-size=" ( set "SLOT_SIZE=!_SA:~12!" & shift & goto :parse_sign_args )
if "!_SA:~0,14!"=="--header-size=" ( set "HEADER_SIZE=!_SA:~14!" & shift & goto :parse_sign_args )
if "!IN_BIN!"=="" ( set "IN_BIN=!_SA!" ) else ( set "OUT_BIN=!_SA!" )
shift
goto :parse_sign_args

:: ## args_done
:: Validates inputs and executes imgtool or compiled C11 MCUboot v2 signer.
:args_done
if "!IN_BIN!"=="" if not "%LIBSCRIPT_TARGET_SYSROOT%"=="" (
    if exist "%LIBSCRIPT_TARGET_SYSROOT%\boot\zephyr.bin" set "IN_BIN=%LIBSCRIPT_TARGET_SYSROOT%\boot\zephyr.bin"
    if "!IN_BIN!"=="" if exist "%LIBSCRIPT_TARGET_SYSROOT%\boot\freertos.bin" set "IN_BIN=%LIBSCRIPT_TARGET_SYSROOT%\boot\freertos.bin"
    if not "!IN_BIN!"=="" if "!OUT_BIN!"=="" set "OUT_BIN=%LIBSCRIPT_TARGET_SYSROOT%\boot\firmware.mcuboot.signed.bin"
)
if "!IN_BIN!"=="" (
    echo [ERROR] sign_firmware.cmd requires an input firmware binary. >&2
    exit /b 1
)
if "!OUT_BIN!"=="" set "OUT_BIN=!IN_BIN!.signed.bin"
for %%P in ("!OUT_BIN!") do (
    if not exist "%%~dpP" mkdir "%%~dpP"
)

where imgtool >nul 2>&1
if not errorlevel 1 (
    if "!KEY_FILE!"=="" (
        set "KEY_DIR=%LIBSCRIPT_HOME%\mcuboot\keys"
        if not exist "!KEY_DIR!" mkdir "!KEY_DIR!"
        set "KEY_FILE=!KEY_DIR!\mcuboot-!KEY_TYPE!.pem"
        if not exist "!KEY_FILE!" imgtool keygen -k "!KEY_FILE!" -t "!KEY_TYPE!" >nul 2>&1
    )
    if exist "!KEY_FILE!" (
        imgtool sign --key "!KEY_FILE!" --header-size "!HEADER_SIZE!" --align 4 --version "1.0.0" --slot-size "!SLOT_SIZE!" --pad --confirm "!IN_BIN!" "!OUT_BIN!.tmp"
        if not errorlevel 1 (
            move /y "!OUT_BIN!.tmp" "!OUT_BIN!" >nul
            echo [OK] Signed MCUboot image via imgtool ^(!KEY_TYPE!^) -^> !OUT_BIN!
            exit /b 0
        )
    )
)

set "SIGNER_DIR=%LIBSCRIPT_HOME%\mcuboot\bin"
if not exist "!SIGNER_DIR!" mkdir "!SIGNER_DIR!"
set "SIGNER_EXE=!SIGNER_DIR!\mcuboot_c_signer_v2.exe"
if not exist "!SIGNER_EXE!" (
    where gcc >nul 2>&1 && gcc -std=c11 -O2 -o "!SIGNER_EXE!" "!SCRIPT_DIR!\mcuboot_c_signer.c"
    if not exist "!SIGNER_EXE!" (
        where clang >nul 2>&1 && clang -std=c11 -O2 -o "!SIGNER_EXE!" "!SCRIPT_DIR!\mcuboot_c_signer.c"
    )
    if not exist "!SIGNER_EXE!" (
        where cl >nul 2>&1 && cl /nologo /O2 /Fe:"!SIGNER_EXE!" "!SCRIPT_DIR!\mcuboot_c_signer.c" >nul 2>&1
    )
)
if exist "!SIGNER_EXE!" (
    "!SIGNER_EXE!" "!IN_BIN!" "!OUT_BIN!.tmp" "!HEADER_SIZE!" "!SLOT_SIZE!" "!KEY_TYPE!"
    if not errorlevel 1 (
        move /y "!OUT_BIN!.tmp" "!OUT_BIN!" >nul
        echo [OK] Signed MCUboot v2 slot image via C11 signer ^(!KEY_TYPE!^) -^> !OUT_BIN!
        exit /b 0
    )
)

echo [ERROR] Neither imgtool nor a C11 compiler for mcuboot_c_signer.c was found. >&2
exit /b 1
