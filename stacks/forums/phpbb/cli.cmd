@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the phpBB forum software stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for phpbb.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=phpbb"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
