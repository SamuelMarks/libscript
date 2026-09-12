@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for HashiCorp Packer on Windows.
::
:: ## Usage
:: Execute this script to dispatch Packer commands.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=packer"
call "%~dp0\..\..\_common\component_core.cmd" %*
