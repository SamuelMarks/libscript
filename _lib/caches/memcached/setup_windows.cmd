@echo off
:: # setup_windows.cmd
::
:: ## Overview
:: Setup script for memcached on Windows.
:: Prepares and delegates to generic Windows setup.
::
:: ## Usage
:: Automatically invoked during libscript memcached installation on Windows.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"

call "%~dp0setup_generic.cmd" %*
exit /b %errorlevel%
