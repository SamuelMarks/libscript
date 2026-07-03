@echo off
:: # setup.cmd
::
:: ## Overview
:: Serves as the primary Windows setup entry point for the AWS Cloud Provider component.
:: It delegates the core initialization logic to the common `setup_base.cmd`.
:: 
:: ## Usage
:: Call this script to trigger the setup process for AWS on Windows.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\_common\setup_base.cmd" %*
