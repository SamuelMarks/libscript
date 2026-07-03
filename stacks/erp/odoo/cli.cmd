@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Odoo ERP system stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for odoo.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=odoo"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
