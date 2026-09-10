@echo off
:: # cli.cmd
:: Command-line interface entry point for VirtualBox on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=virtualbox"
call "%~dp0\..\..\_common\component_core.cmd" %*
