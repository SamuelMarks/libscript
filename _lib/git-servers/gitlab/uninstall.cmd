@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for GitLab on Windows.
::
:: ## Usage
:: Invokes `uninstall_base.cmd` to clean up GitLab.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
