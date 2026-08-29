@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the WooCommerce e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for woocommerce.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=woocommerce"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
