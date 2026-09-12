@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup entry point for HashiCorp Packer on Windows.
::
:: ## Usage
:: Call this script to configure Packer on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
