@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the WooCommerce e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for woocommerce.

setlocal EnableDelayedExpansion
set "THIS_FILE=%~f0"
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
