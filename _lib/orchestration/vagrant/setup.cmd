@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup entry point for Vagrant on Windows.
::
:: ## Usage
:: Call this script to configure Vagrant on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
