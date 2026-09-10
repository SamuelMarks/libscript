@echo off
:: # env.cmd
:: Windows environment configuration for QEMU.
set "THIS_FILE=%~f0"

if exist "C:\Program Files\qemu" (
    set "PATH=C:\Program Files\qemu;%PATH%"
)
