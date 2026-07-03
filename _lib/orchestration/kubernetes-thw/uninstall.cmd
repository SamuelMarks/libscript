@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for kubernetes-thw on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up resources.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
