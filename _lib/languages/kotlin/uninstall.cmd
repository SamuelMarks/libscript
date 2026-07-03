@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Kotlin on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Kotlin.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
