@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Drupal CMS stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for drupal.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=drupal"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
