@echo off
:: # setup.cmd
::
:: ## Overview
:: Installation and configuration script for the pub component on Windows.
:: It handles downloading, verifying, and installing the component on the host system.
::
:: ## Usage
:: Execute this script to install or configure the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
