@echo off
:: # cli.cmd
::
:: ## Overview
:: Serves as the command-line interface entry point for the Ollama component on Windows.
:: It explicitly sets the target package to `ollama` and delegates execution
:: to the common `component_core.cmd`.
:: 
:: ## Usage
:: Call this script to run the component's CLI logic.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=ollama"
call "%~dp0\..\..\_common\component_core.cmd" %*
