@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Magento e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for magento.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=magento"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
