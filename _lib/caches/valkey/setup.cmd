@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the Valkey Cache component.
:: It delegates the core initialization logic to the common `setup_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger the setup process for Valkey on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
