@echo off
:: # env.cmd
::
:: ## Overview
:: Environment export script for QEMU on Windows.
::
:: ## Usage
:: Call this script to set QEMU environment variables.

set "THIS_FILE=%~f0"

if exist "C:\Program Files\qemu" (
    set "PATH=C:\Program Files\qemu;%PATH%"
)
