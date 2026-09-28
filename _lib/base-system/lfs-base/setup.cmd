@echo off
:: ## Overview
:: Windows Batch companion for LFS Stage 3 Base System and FHS Layout.
:: Implements Option A Win32 Hard-Fail boundary proforma.
::
:: ## Usage
:: _lib\base-system\lfs-base\setup.cmd [install|clean|status]

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
        goto end
    ) ELSE (
        SET "STACK=!STACK!%THIS_FILE%;"
        echo [CONTINUE] processing "%THIS_FILE%"
    )
)

SET "SCRIPT_DIR=%~dp0"
SET "LIBSCRIPT_ROOT_DIR=%SCRIPT_DIR%..\..\.."
FOR %%i IN ("%LIBSCRIPT_ROOT_DIR%") DO SET "LIBSCRIPT_ROOT_DIR=%%~fi"

IF "%~1"=="status" (
    echo === LFS Base System Status (Win32) ===
    echo LFS rootfs assembly executes inside Linux container or Vagrant VM builder.
    goto end
)

:: Option A Win32 Hard-Fail Boundary Proforma
echo [ERROR] Native Linux kernel assembly (mount/unshare) and LFS rootfs construction is unavailable on Win32. >&2
echo [ERROR] Please execute via container or VM builder: vm_builder.cmd >&2
exit /b 86

:end
exit /b 0
