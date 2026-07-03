@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for PostgreSQL on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up PostgreSQL.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
