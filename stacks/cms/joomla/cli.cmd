@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Joomla CMS stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for joomla.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=joomla"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
