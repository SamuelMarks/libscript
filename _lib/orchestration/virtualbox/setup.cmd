@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup entry point for VirtualBox on Windows.
::
:: ## Usage
:: Call this script to configure VirtualBox on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
