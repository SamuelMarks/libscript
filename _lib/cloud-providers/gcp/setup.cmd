@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for the GCP cloud provider on Windows.
::
:: ## Usage
:: Invokes `setup_base.cmd` to route to the correct generic or OS-specific script.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
