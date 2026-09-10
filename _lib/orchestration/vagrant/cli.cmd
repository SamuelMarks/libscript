@echo off
:: # cli.cmd
:: Command-line interface entry point for Vagrant on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=vagrant"
call "%~dp0\..\..\_common\component_core.cmd" %*
