@echo off
:: # cli.cmd
::
:: ## Overview
:: Command-line interface dispatcher for the Open edX stack on Windows.

::
:: ## Usage
:: Call this script to route CLI commands for openedx on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
set "PACKAGE_NAME=openedx"
call "%~dp0..\..\..\_lib\_common\component_core.cmd" %*
