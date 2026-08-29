@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the OpenVPN networking stack stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for openvpn.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=openvpn"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
