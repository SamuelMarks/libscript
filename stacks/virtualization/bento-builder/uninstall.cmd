@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation entry point for Bento Builder stack on Windows.
::
:: ## Usage
:: Call this script to uninstall Bento Builder on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\..\_lib\_common\uninstall_base.cmd" %*
