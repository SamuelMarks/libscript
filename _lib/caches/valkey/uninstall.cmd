@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Serves as the primary Windows generic uninstall script for the Valkey component.
:: It explicitly delegates execution to the common `uninstall_base.cmd` to perform
:: standard teardown processes.
:: 
:: ## Usage
:: Call this script to uninstall the Valkey component on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
