@echo off
:: # setup.cmd
::
:: ## Overview
:: Installation and configuration script for the psmux component on Windows.
:: It handles downloading, verifying, and installing the component on the host system.
::
:: ## Usage
:: Execute this script to install or configure the component.
set "THIS_FILE=%~f0"

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*
