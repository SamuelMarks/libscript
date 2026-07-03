@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for the GCP GPU VM component on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up GCP GPU VM configuration.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
