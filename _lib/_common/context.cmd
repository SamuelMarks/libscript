@echo off
:: # context.cmd
::
:: ## Overview
:: Codifies the standard context contract variables and idempotency stamp
:: protocols passed between Tier 2 synthesizers and Tier 1 leaf recipes.
::
:: ## Usage
:: Call this script to initialize and validate standard context variables:
::   call "%LIBSCRIPT_ROOT_DIR%\_lib\_common\context.cmd"

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

IF NOT DEFINED LIBSCRIPT_ROOT_DIR (
    SET "LIBSCRIPT_ROOT_DIR=%~dp0..\.."
)

IF NOT DEFINED LIBSCRIPT_BUILD_DIR (
    SET "LIBSCRIPT_BUILD_DIR=%TEMP%\libscript_build"
)
IF NOT DEFINED LIBSCRIPT_TARGET_SYSROOT (
    SET "LIBSCRIPT_TARGET_SYSROOT=%LIBSCRIPT_BUILD_DIR%\sysroot"
)
IF NOT DEFINED LIBSCRIPT_HOST_ROOT (
    SET "LIBSCRIPT_HOST_ROOT=/tools"
)
IF NOT DEFINED LIBSCRIPT_STAGE (
    SET "LIBSCRIPT_STAGE=stage0"
)
IF NOT DEFINED LIBSCRIPT_TARGET_ARCH (
    SET "LIBSCRIPT_TARGET_ARCH=x86_64"
)
IF NOT DEFINED LIBSCRIPT_TARGET_LIBC (
    SET "LIBSCRIPT_TARGET_LIBC=glibc"
)
IF NOT DEFINED LIBSCRIPT_TARGET_OS (
    SET "LIBSCRIPT_TARGET_OS=linux"
)
IF NOT DEFINED LIBSCRIPT_OFFLINE (
    SET "LIBSCRIPT_OFFLINE=0"
)
IF NOT DEFINED LIBSCRIPT_CACHE_DIR (
    SET "LIBSCRIPT_CACHE_DIR=%LIBSCRIPT_ROOT_DIR%\cache"
)

SET "LIBSCRIPT_STAMP_DIR=%LIBSCRIPT_TARGET_SYSROOT%\var\lib\libscript\stamps"

if not exist "%LIBSCRIPT_STAMP_DIR%" mkdir "%LIBSCRIPT_STAMP_DIR%"

exit /b 0
