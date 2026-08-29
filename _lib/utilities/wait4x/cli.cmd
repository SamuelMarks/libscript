@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entrypoint for the wait4x component on Windows.
:: It initializes the lifecycle and delegates execution to the shared batch components.
::
:: ## Usage
:: Execute this script directly to run the CLI functionality for the component.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=wait4x"
call "%~dp0\..\..\_common\component_core.cmd" %*
