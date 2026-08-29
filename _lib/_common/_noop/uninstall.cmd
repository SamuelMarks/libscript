@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Serves as the primary uninstall entry point for the `_noop` component on Windows.
:: It delegates execution to the common `uninstall_base.cmd` to provide
:: consistent teardown management.
:: 
:: ## Usage
:: Call this script to trigger the uninstallation process for `_noop`.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
