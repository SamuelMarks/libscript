@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the go-pm component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script directly to run the CLI functionality for the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
if not defined PACKAGE_NAME for %%I in ("%~dp0.") do set "PACKAGE_NAME=%%~nxI"
call "%~dp0\..\..\_common\component_core.cmd" %*
