@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Serves as the primary Windows generic uninstall script for the Rust Server component.
:: It explicitly delegates execution to the common `uninstall_base.cmd` to perform
:: standard teardown processes.
:: 
:: ## Usage
:: Call this script to uninstall the Rust Server component on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
