@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the Redis Cache component.
:: It delegates the core initialization logic to the common `setup_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger the setup process for Redis on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\setup_base.cmd" %*
