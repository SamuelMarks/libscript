@echo off
:: # setup.cmd
::
:: ## Overview
:: Primary setup script for the Azure cloud provider on Windows.
::
:: ## Usage
:: Invokes `setup_base.cmd` to route to the correct generic or OS-specific script.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\setup_base.cmd" %*
