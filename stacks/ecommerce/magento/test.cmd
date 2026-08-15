@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the Magento e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for magento.

setlocal EnableDelayedExpansion
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0test.ps1"
