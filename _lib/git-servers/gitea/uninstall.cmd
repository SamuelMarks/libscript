@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Gitea on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up Gitea.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
