@echo off
:: # setup_windows.cmd
::
:: ## Overview
:: Windows setup entry point for Exim.

::
:: ## Usage
:: Call this script to trigger setup for exim on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0setup_generic.cmd" %*
