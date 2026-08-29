@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation script for the gradle component on Windows.
:: It safely removes the component and its associated files from the host system.
::
:: ## Usage
:: Execute this script to remove the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\uninstall_base.cmd" %*
