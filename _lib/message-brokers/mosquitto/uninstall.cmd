@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Mosquitto on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Mosquitto.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
