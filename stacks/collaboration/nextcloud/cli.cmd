@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Nextcloud collaboration platform stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for nextcloud.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=nextcloud"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
