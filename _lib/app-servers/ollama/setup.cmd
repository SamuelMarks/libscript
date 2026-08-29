@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the Ollama component.
:: It sets the target package to `ollama` and delegates the core initialization
:: logic to the common `setup_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger the setup process for Ollama on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=ollama"
call "%~dp0\..\..\_common\setup_base.cmd" %*
