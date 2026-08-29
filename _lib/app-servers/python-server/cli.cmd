@echo off
:: # cli.cmd
::
:: ## Overview
:: Serves as the command-line interface entry point for the Python Server component on Windows.
:: It explicitly sets the target package to `python-server` and delegates execution
:: to the common `component_core.cmd`.
:: 
:: ## Usage
:: Call this script to run the component's CLI logic.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=python-server"
call "%~dp0\..\..\_common\component_core.cmd" %*
