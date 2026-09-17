@echo off
:: # setup.cmd
::
:: ## Overview
:: Setup entry point for Open edX stack on Windows.

::
:: ## Usage
:: Call this script to trigger setup for openedx on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0setup_generic.cmd" %*
