@echo off
:: # test.cmd
::
:: ## Overview
:: Implements automated tests to verify the correctness of the PrestaShop e-commerce platform stack.
:: 
:: ## Usage
:: Execute this script to run the test suite for prestashop.

setlocal EnableDelayedExpansion
call "%~dp0\..\..\..\_lib\_common\test_base.cmd"
