@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the WordPress CMS stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for wordpress.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=wordpress"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
