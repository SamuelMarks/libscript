@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface entry point for OpenSSH on Windows.
::
:: ## Usage
:: Execute this script to perform CLI actions for OpenSSH.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=openssh"
call "%~dp0..\..\_common\component_core.cmd" %*
