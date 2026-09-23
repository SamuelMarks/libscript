@echo off
:: # provision_disk.cmd
::
:: ## Overview
:: Provisions sparse disk images and configures partition tables on Linux.
::
:: ## Usage
:: provision_disk.cmd [OPTIONS]

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

echo [ERROR] %~nx0 requires Linux kernel primitives (e.g., mount, losetup, chroot, unshare).
echo [ERROR] Direct native execution on Windows is unsupported for this sub-operation.
echo [INFO]  Execute this operation within a Linux environment or via a builder worker:
echo [INFO]    libscript.cmd build os --worker=wsl2 ^| --worker=docker ^| --worker=qemu
exit /b 86
