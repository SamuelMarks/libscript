@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Vagrant on Windows.
::
:: ## Usage
:: Execute this script to dispatch Vagrant commands.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=vagrant"
call "%~dp0\..\..\_common\component_core.cmd" %*
