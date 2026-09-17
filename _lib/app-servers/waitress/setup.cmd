@echo off
:: # setup.cmd
::
:: ## Overview
:: Windows setup entry point for Waitress.

::
:: ## Usage
:: Call this script to trigger setup for waitress on Windows.
setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
call "%~dp0\..\..\_common\setup_base.cmd" %*
