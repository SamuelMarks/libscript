@echo off
:: # env.cmd
::
:: ## Overview
:: Environment export script for VirtualBox on Windows.
::
:: ## Usage
:: Call this script to set VirtualBox environment variables.

set "THIS_FILE=%~f0"

if exist "C:\Program Files\Oracle\VirtualBox" (
    set "PATH=C:\Program Files\Oracle\VirtualBox;%PATH%"
)
