@echo off
:: # uninstall.cmd
::
:: ## Overview
:: Uninstallation script for the psmux component on Windows.
:: It safely removes the component and its associated files from the host system.
::
:: ## Usage
:: Execute this script to remove the component.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0uninstall.ps1" %*
