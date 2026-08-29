@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for the GCP CLI on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up GCP CLI configuration.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
