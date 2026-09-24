@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for Hetzner Cloud provider on Windows.
::
:: ## Usage
:: Execute this script to perform CLI actions for Hetzner.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=hetzner"
call "%~dp0..\..\_common\component_core.cmd" %*
