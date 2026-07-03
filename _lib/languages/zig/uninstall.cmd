@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Zig on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Zig.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
