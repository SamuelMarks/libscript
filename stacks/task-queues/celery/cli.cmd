@echo off
:: # cli.cmd
::
:: ## Overview
:: Provides the command-line interface logic for the Celery task queue stack.
:: 
:: ## Usage
:: Execute this script to trigger the CLI behavior for celery.

setlocal EnableDelayedExpansion
set "PACKAGE_NAME=celery"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
