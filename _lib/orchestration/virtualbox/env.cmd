@echo off
:: # env.cmd
:: Windows environment configuration for VirtualBox.
set "THIS_FILE=%~f0"

if exist "C:\Program Files\Oracle\VirtualBox" (
    set "PATH=C:\Program Files\Oracle\VirtualBox;%PATH%"
)
