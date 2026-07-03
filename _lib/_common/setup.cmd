@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for components.
:: It automatically delegates execution to the component's `setup_base.cmd`
:: to provide consistent initialization.
:: 
:: ## Usage
:: Call this script to trigger the standard setup process on Windows.

setlocal EnableDelayedExpansion
call "%~dp0setup_base.cmd" %*
