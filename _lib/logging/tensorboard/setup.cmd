@echo off
:: # setup.cmd
::
:: ## Overview
:: Setup script for TensorBoard on Windows.
::
:: ## Usage
:: Delegates to PowerShell setup script.

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0setup.ps1" %*