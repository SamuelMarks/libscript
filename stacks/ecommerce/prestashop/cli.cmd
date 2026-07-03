@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the PrestaShop e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for prestashop.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=prestashop"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
