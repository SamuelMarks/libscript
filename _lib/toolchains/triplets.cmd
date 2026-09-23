@echo off
:: # triplets.cmd
::
:: ## Overview
:: Standard cross-toolchain triplet and compiler security flags definitions for Windows.
:: Exports canonical target triplets, security hardening flags, and SOURCE_DATE_EPOCH.
::
:: ## Usage
:: triplets.cmd [target_arch] [target_libc] [target_os]

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

SET "searchVal=;%THIS_FILE%;"
IF NOT DEFINED STACK (
    SET "STACK=;%THIS_FILE%;"
    echo [CONTINUE] processing "%THIS_FILE%"
) ELSE (
    IF NOT "!STACK:%searchVal%=!"=="!STACK!" (
        echo [STOP]     processing "%THIS_FILE%"
        SET ERRORLEVEL=0
        goto :eof
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

if "%~1"=="--help" (
    echo Usage: %~nx0 [target_arch] [target_libc] [target_os]
    echo Exports standard cross-toolchain triplet definitions.
    exit /b 0
)
if "%~1"=="-h" (
    echo Usage: %~nx0 [target_arch] [target_libc] [target_os]
    echo Exports standard cross-toolchain triplet definitions.
    exit /b 0
)

set "TARGET_ARCH=%~1"
if "!TARGET_ARCH!"=="" (
    if defined LIBSCRIPT_TARGET_ARCH (
        set "TARGET_ARCH=!LIBSCRIPT_TARGET_ARCH!"
    ) else (
        set "TARGET_ARCH=x86_64"
    )
)

set "TARGET_LIBC=%~2"
if "!TARGET_LIBC!"=="" (
    if defined LIBSCRIPT_TARGET_LIBC (
        set "TARGET_LIBC=!LIBSCRIPT_TARGET_LIBC!"
    ) else (
        set "TARGET_LIBC=glibc"
    )
)

set "TARGET_OS=%~3"
if "!TARGET_OS!"=="" (
    if defined LIBSCRIPT_TARGET_OS (
        set "TARGET_OS=!LIBSCRIPT_TARGET_OS!"
    ) else (
        set "TARGET_OS=linux"
    )
)

if "!TARGET_OS!"=="freebsd" (
    set "LIBSCRIPT_TARGET_TRIPLET=!TARGET_ARCH!-unknown-freebsd14.0"
) else if "!TARGET_OS!"=="unikraft" (
    set "LIBSCRIPT_TARGET_TRIPLET=!TARGET_ARCH!-unikraft-elf"
) else (
    if "!TARGET_LIBC!"=="musl" (
        set "LIBSCRIPT_TARGET_TRIPLET=!TARGET_ARCH!-libscript-linux-musl"
    ) else (
        set "LIBSCRIPT_TARGET_TRIPLET=!TARGET_ARCH!-libscript-linux-gnu"
    )
)

set "LIBSCRIPT_SECURITY_CFLAGS=-fno-common -fPIC -fstack-protector-strong -D_FORTIFY_SOURCE=2"
set "LIBSCRIPT_SECURITY_LDFLAGS=-Wl,-z,relro -Wl,-z,now"
if not defined SOURCE_DATE_EPOCH set "SOURCE_DATE_EPOCH=1700000000"

echo [INFO] Triplet: !LIBSCRIPT_TARGET_TRIPLET!
echo [INFO] CFLAGS:  !LIBSCRIPT_SECURITY_CFLAGS!

endlocal & (
    set "LIBSCRIPT_TARGET_TRIPLET=%LIBSCRIPT_TARGET_TRIPLET%"
    set "LIBSCRIPT_SECURITY_CFLAGS=%LIBSCRIPT_SECURITY_CFLAGS%"
    set "LIBSCRIPT_SECURITY_LDFLAGS=%LIBSCRIPT_SECURITY_LDFLAGS%"
    set "SOURCE_DATE_EPOCH=%SOURCE_DATE_EPOCH%"
)
