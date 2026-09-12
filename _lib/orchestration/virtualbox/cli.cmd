@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for VirtualBox on Windows.
::
:: ## Usage
:: Execute this script to dispatch VirtualBox commands.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=virtualbox"
call "%~dp0\..\..\_common\component_core.cmd" %*
