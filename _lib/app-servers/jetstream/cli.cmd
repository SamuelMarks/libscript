@echo off
:: # cli.cmd
::
:: ## Overview
:: Serves as the command-line interface entry point for the Jetstream component on Windows.
:: It explicitly sets the target package to `huggingface_hub` and delegates execution
:: to the common `component_core.cmd`.
:: 
:: ## Usage
:: Call this script to run the component's CLI logic.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=huggingface_hub"
call "%~dp0\..\..\_common\component_core.cmd" %*
