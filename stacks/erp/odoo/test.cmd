@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Odoo ERP system stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for odoo.

setlocal EnableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
